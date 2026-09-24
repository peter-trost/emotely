/**
 * Finds the comments in a source file, and only the comments: a string
 * literal, a regular expression or a heredoc that happens to contain `//` or
 * `#` is code, not a comment. These are not full parsers; they track exactly
 * the constructs that decide whether a character sits inside a comment.
 */
import { CLikeLexer, DART, TYPESCRIPT } from "./c-like-lexer.ts";
import { ShellLexer } from "./shell-lexer.ts";
import type { Span } from "./span.ts";

export type Language = "dart" | "shell" | "typescript";

export function commentSpans(language: Language, source: string): Span[] {
  if (language === "shell") {
    return new ShellLexer(source).run();
  }
  return new CLikeLexer(source, language === "dart" ? DART : TYPESCRIPT).run();
}
