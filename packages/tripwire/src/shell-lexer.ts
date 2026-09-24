import { lineEnd, type Span } from "./span.ts";

type Heredoc = { delimiter: string; stripTabs: boolean };

const HEREDOC = /^(-?)[ \t]*(\\?)(['"]?)([A-Za-z_]\w*)\3/;
const LEADING_TABS = /^\t+/;
// A `#` starts a comment only at the start of a word.
const WORD_BREAK = /[\s;&|()]/;

/** POSIX shell and bash: `#` comments around quotes and heredoc bodies. */
export class ShellLexer {
  private readonly source: string;
  private readonly spans: Span[] = [];
  private readonly heredocs: Heredoc[] = [];
  private at = 0;

  constructor(source: string) {
    this.source = source;
  }

  run(): Span[] {
    while (this.at < this.source.length) {
      this.step(this.source[this.at] ?? "");
    }
    return this.spans;
  }

  private step(char: string): void {
    if (char === "\n" && this.heredocs.length > 0) {
      this.at = this.skipHeredocs(this.at + 1);
    } else if (char === "\\") {
      this.at += 2;
    } else if (char === "'") {
      this.singleQuoted();
    } else if (char === '"') {
      this.doubleQuoted();
    } else if (char === "#" && this.wordStart()) {
      const end = lineEnd(this.source, this.at);
      this.spans.push({ start: this.at, end, doc: false });
      this.at = end;
    } else if (this.source.startsWith("<<", this.at)) {
      this.heredoc();
    } else {
      this.at++;
    }
  }

  private wordStart(): boolean {
    return this.at === 0 || WORD_BREAK.test(this.source[this.at - 1] ?? "");
  }

  private singleQuoted(): void {
    const end = this.source.indexOf("'", this.at + 1);
    this.at = end === -1 ? this.source.length : end + 1;
  }

  private doubleQuoted(): void {
    this.at++;
    while (this.at < this.source.length && this.source[this.at] !== '"') {
      this.at += this.source[this.at] === "\\" ? 2 : 1;
    }
    this.at++;
  }

  private heredoc(): void {
    this.at += 2;
    if (this.source[this.at] === "<") {
      // `<<<` is a here-string: the word after it is ordinary code.
      this.at++;
      return;
    }
    const match = HEREDOC.exec(this.source.slice(this.at));
    if (match !== null) {
      this.heredocs.push({
        delimiter: match[4] ?? "",
        stripTabs: match[1] === "-",
      });
      this.at += match[0].length;
    }
  }

  /** Past the bodies of the heredocs opened on the line just ended. */
  private skipHeredocs(from: number): number {
    let at = from;
    for (const { delimiter, stripTabs } of this.heredocs.splice(0)) {
      while (at < this.source.length) {
        const end = lineEnd(this.source, at);
        const line = this.source.slice(at, end);
        at = end + 1;
        if ((stripTabs ? line.replace(LEADING_TABS, "") : line) === delimiter) {
          break;
        }
      }
    }
    return at;
  }
}
