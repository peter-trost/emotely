import { lineEnd, type Span } from "./span.ts";

export type Dialect = {
  quotes: string;
  interpolating: string;
  nestedBlocks: boolean;
  tripleQuotes: boolean;
  rawPrefix: boolean;
  regexLiterals: boolean;
  lineDoc: boolean;
};

export const DART: Dialect = {
  quotes: "'\"",
  interpolating: "'\"",
  nestedBlocks: true,
  tripleQuotes: true,
  rawPrefix: true,
  regexLiterals: false,
  lineDoc: true,
};

export const TYPESCRIPT: Dialect = {
  quotes: "'\"`",
  interpolating: "`",
  nestedBlocks: false,
  tripleQuotes: false,
  rawPrefix: false,
  regexLiterals: true,
  lineDoc: false,
};

type StringForm = { close: string; raw: boolean; multiline: boolean };

const TRIPLE = 3;
const IDENTIFIER = /[\w$]/;
const WHITESPACE = /\s/;
// After one of these, a `/` starts a regular expression, not a division.
const BEFORE_REGEX = /[(,=:[!&|?{};+\-*%<>~^]/;
const KEYWORDS_BEFORE_REGEX = new Set([
  "await",
  "case",
  "delete",
  "do",
  "else",
  "in",
  "instanceof",
  "new",
  "of",
  "return",
  "throw",
  "typeof",
  "void",
  "yield",
]);

/** Dart and TypeScript: `//` and `/* *\/` comments around quoted strings. */
export class CLikeLexer {
  private readonly source: string;
  private readonly dialect: Dialect;
  private readonly spans: Span[] = [];
  private at = 0;

  constructor(source: string, dialect: Dialect) {
    this.source = source;
    this.dialect = dialect;
  }

  run(): Span[] {
    this.code(false);
    return this.spans;
  }

  /** Code up to the end, or up to the `}` closing an interpolation. */
  private code(interpolation: boolean): void {
    let depth = 0;
    while (this.at < this.source.length) {
      const char = this.source[this.at] ?? "";
      if (this.opensComment()) {
        continue;
      }
      if (this.dialect.quotes.includes(char)) {
        this.string(char);
      } else if (char === "/" && this.regexMayStart()) {
        this.regex();
      } else if (char === "}" && interpolation && depth === 0) {
        this.at++;
        return;
      } else {
        depth += braceDelta(char);
        this.at++;
      }
    }
  }

  private opensComment(): boolean {
    if (this.source.startsWith("//", this.at)) {
      this.lineComment();
      return true;
    }
    if (this.source.startsWith("/*", this.at)) {
      this.blockComment();
      return true;
    }
    return false;
  }

  private lineComment(): void {
    const start = this.at;
    const end = lineEnd(this.source, start);
    const doc =
      this.dialect.lineDoc &&
      this.source.startsWith("///", start) &&
      !this.source.startsWith("////", start);
    this.spans.push({ start, end, doc });
    this.at = end;
  }

  private blockComment(): void {
    const start = this.at;
    const doc =
      this.source.startsWith("/**", start) &&
      !this.source.startsWith("/**/", start);
    let depth = 0;
    let at = start;
    while (at < this.source.length) {
      if (
        this.source.startsWith("/*", at) &&
        (this.dialect.nestedBlocks || depth === 0)
      ) {
        depth++;
        at += 2;
      } else if (this.source.startsWith("*/", at)) {
        depth--;
        at += 2;
        if (depth === 0) {
          break;
        }
      } else {
        at++;
      }
    }
    this.spans.push({ start, end: at, doc });
    this.at = at;
  }

  private string(quote: string): void {
    const form = this.stringForm(quote);
    this.at += form.close.length;
    while (this.at < this.source.length && !this.stringEnds(form)) {
      this.stringStep(form, quote);
    }
  }

  private stringForm(quote: string): StringForm {
    const { source, at, dialect } = this;
    const raw =
      dialect.rawPrefix &&
      source[at - 1] === "r" &&
      !IDENTIFIER.test(source[at - 2] ?? " ");
    const triple =
      dialect.tripleQuotes && source.startsWith(quote.repeat(TRIPLE), at);
    return {
      close: triple ? quote.repeat(TRIPLE) : quote,
      raw,
      multiline: triple || quote === "`",
    };
  }

  /** Consumes the closing quote and says so; stops an unterminated line too. */
  private stringEnds({ close, multiline }: StringForm): boolean {
    if (this.source.startsWith(close, this.at)) {
      this.at += close.length;
      return true;
    }
    // Unterminated: stop at the line end, so one stray quote cannot swallow
    // the rest of the file.
    return this.source[this.at] === "\n" && !multiline;
  }

  private stringStep({ raw }: StringForm, quote: string): void {
    if (raw) {
      this.at++;
    } else if (this.source[this.at] === "\\") {
      this.at += 2;
    } else if (
      this.dialect.interpolating.includes(quote) &&
      this.source.startsWith("${", this.at)
    ) {
      this.at += 2;
      this.code(true);
    } else {
      this.at++;
    }
  }

  private regexMayStart(): boolean {
    if (!this.dialect.regexLiterals) {
      return false;
    }
    let at = this.at - 1;
    while (at >= 0 && WHITESPACE.test(this.source[at] ?? "")) {
      at--;
    }
    const before = this.source[at];
    if (before === undefined || BEFORE_REGEX.test(before)) {
      return true;
    }
    let wordStart = at;
    while (wordStart > 0 && IDENTIFIER.test(this.source[wordStart - 1] ?? "")) {
      wordStart--;
    }
    return KEYWORDS_BEFORE_REGEX.has(this.source.slice(wordStart, at + 1));
  }

  private regex(): void {
    let inClass = false;
    this.at++;
    while (this.at < this.source.length) {
      const char = this.source[this.at];
      if (char === "\n") {
        return;
      }
      this.at += char === "\\" ? 2 : 1;
      if (char === "[") {
        inClass = true;
      } else if (char === "]") {
        inClass = false;
      } else if (char === "/" && !inClass) {
        return;
      }
    }
  }
}

function braceDelta(char: string): number {
  if (char === "{") {
    return 1;
  }
  return char === "}" ? -1 : 0;
}
