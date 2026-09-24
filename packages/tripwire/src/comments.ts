/**
 * The comment tripwire's rule. Only comments are read, never strings or
 * code, and the rule is checked line by line.
 *
 * A workaround comment fails:
 * - one of the {@link TAGS}, in any comment;
 * - one of the {@link PHRASES}, in an implementation comment (`//`,
 *   `/* *\/`, `#`). Documentation comments (`///`, `/** *\/`) describe
 *   behavior to a caller and may use their words.
 *
 * A suppression fails without a reason of at least {@link REASON_WORDS}
 * words, either after the directive on its own line or in a comment standing
 * alone on the line above (below, for a directive on a file's first line).
 * The line above must not be another directive: each carries its own reason.
 */
import { commentSpans, type Language } from "./lexers.ts";
import type { Span } from "./span.ts";

export type Finding = {
  line: number;
  rule: "workaround" | "suppression";
  match: string;
};

/** One physical line of a comment, its comment markers removed. */
type CommentLine = {
  line: number;
  text: string;
  doc: boolean;
  /** Nothing but this comment on the line. */
  alone: boolean;
};

/**
 * The four tags in upper case anywhere; in lower case only written as a tag,
 * followed by a colon or a parenthesis, so the words stay usable in prose.
 * (This comment cannot spell them out: the tripwire reads its own source.)
 */
const TAGS = [
  /\b(?:TODO|FIXME|HACK|XXX)\b/,
  /\b(?:todo|fixme|hack|xxx)(?=\s*[:(])/i,
];

/**
 * "workaround" is the noun only; the verb "work around" describes what a
 * user or caller does. "temporary" passes before a thing that exists at run
 * time ("a temporary file"), which it describes rather than the code.
 */
const PHRASES = [
  /\bwork-?arounds?\b/i,
  /\bfor now\b/i,
  /\btemporarily\b/i,
  /\btemporary\b(?!\s+(?:accounts?|branch(?:es)?|buffers?|cop(?:y|ies)|credentials?|dir(?:ectory|ectories|s)?|files?|folders?|keys?|passwords?|paths?|tables?|tokens?|values?|variables?|worktrees?)\b)/i,
];

/**
 * A suppression, when a comment starts with one: group 1 is the directive
 * itself, group 2 whatever follows it on the line, where a reason may sit.
 * A directive that only closes a range (`coverage:ignore-end`,
 * `biome-ignore-end`) needs no reason; the one that opened it has it.
 */
const DIRECTIVES = [
  // Dart analyzer; a rule name is snake_case or `type=…`, so prose after a
  // comma is not taken for one.
  /^(ignore(?:_for_file)?:\s*(?:type=\w+|\w+_\w+)(?:\s*,\s*(?:type=\w+|\w+_\w+))*)(.*)$/,
  /^(biome-ignore(?:-all|-start)?(?:\s+[^\s:]+)?)(?::(.*))?$/,
  /^(coverage:ignore-(?:file|line|start))\b(.*)$/,
  /^(cognitive_complexity:ignore(?:_for_file)?)\b(.*)$/,
  /^(@ts-(?:ignore|expect-error|nocheck))\b(.*)$/,
  /^(shellcheck\s+disable=[\w,]+)(.*)$/,
];

/** How many words a reason needs: more than a rule name or "needed here". */
export const REASON_WORDS = 4;

export function scan(path: string, source: string): Finding[] {
  const language = languageOf(path);
  if (language === undefined) {
    return [];
  }
  const comments = commentLines(language, source);
  const byLine = new Map<number, CommentLine>();
  for (const comment of comments) {
    if (!byLine.has(comment.line)) {
      byLine.set(comment.line, comment);
    }
  }
  return comments.flatMap((comment) => [
    ...workaround(comment),
    ...suppression(comment, byLine),
  ]);
}

function workaround(comment: CommentLine): Finding[] {
  const match =
    firstMatch(TAGS, comment.text) ??
    (comment.doc ? undefined : firstMatch(PHRASES, comment.text));
  return match === undefined
    ? []
    : [{ line: comment.line, rule: "workaround", match }];
}

function suppression(
  comment: CommentLine,
  byLine: ReadonlyMap<number, CommentLine>,
): Finding[] {
  const directive = directiveOf(comment.text);
  if (
    directive === undefined ||
    words(directive.rest) >= REASON_WORDS ||
    isReason(byLine.get(reasonLine(comment.line)))
  ) {
    return [];
  }
  return [{ line: comment.line, rule: "suppression", match: directive.name }];
}

/** The line above; below only for line 1, where nothing can sit above. */
function reasonLine(line: number): number {
  return line === 1 ? line + 1 : line - 1;
}

function isReason(comment: CommentLine | undefined): boolean {
  return (
    comment?.alone === true &&
    directiveOf(comment.text) === undefined &&
    words(comment.text) >= REASON_WORDS
  );
}

function directiveOf(text: string): { name: string; rest: string } | undefined {
  for (const pattern of DIRECTIVES) {
    const match = pattern.exec(text);
    if (match !== null) {
      return { name: (match[1] ?? "").trim(), rest: match[2] ?? "" };
    }
  }
}

const SPACE = /\s+/;
const LETTER = /\p{L}/u;

/** Words with at least one letter: a rule name's punctuation is not a word. */
function words(text: string): number {
  return text.split(SPACE).filter((word) => LETTER.test(word)).length;
}

function firstMatch(
  patterns: readonly RegExp[],
  text: string,
): string | undefined {
  for (const pattern of patterns) {
    const match = pattern.exec(text);
    if (match !== null) {
      return match[0];
    }
  }
}

const SCRIPT = /\.[cm]?[jt]s$/;

function languageOf(path: string): Language | undefined {
  if (path.endsWith(".dart")) {
    return "dart";
  }
  if (path.endsWith(".sh")) {
    return "shell";
  }
  return SCRIPT.test(path) ? "typescript" : undefined;
}

function commentLines(language: Language, source: string): CommentLine[] {
  const starts = lineStarts(source);
  return commentSpans(language, source).flatMap((span) =>
    linesOf(source, span, starts),
  );
}

function linesOf(
  source: string,
  span: Span,
  starts: readonly number[],
): CommentLine[] {
  const first = lineIndex(starts, span.start);
  const before = source.slice(starts[first] ?? 0, span.start);
  return source
    .slice(span.start, span.end)
    .split("\n")
    .map((text, offset) => ({
      line: first + offset + 1,
      text: withoutMarkers(text),
      doc: span.doc,
      alone: offset > 0 || before.trim() === "",
    }));
}

const CLOSER = /\*+\/\s*$/;
const OPENER = /^\s*(?:\/{2,}|\/\*+|\*+|#+)?/;

function withoutMarkers(text: string): string {
  return text.replace(CLOSER, "").replace(OPENER, "").trim();
}

function lineStarts(source: string): number[] {
  const starts = [0];
  for (
    let at = source.indexOf("\n");
    at !== -1;
    at = source.indexOf("\n", at + 1)
  ) {
    starts.push(at + 1);
  }
  return starts;
}

/** The 0-based line holding `offset`. */
function lineIndex(starts: readonly number[], offset: number): number {
  let low = 0;
  let high = starts.length - 1;
  while (low < high) {
    const middle = Math.ceil((low + high) / 2);
    if ((starts[middle] ?? 0) <= offset) {
      low = middle;
    } else {
      high = middle - 1;
    }
  }
  return low;
}
