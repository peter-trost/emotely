/** A comment's source range; `doc` marks documentation comments. */
export type Span = { start: number; end: number; doc: boolean };

/** The offset of the newline ending the line that holds `from`. */
export function lineEnd(source: string, from: number): number {
  const end = source.indexOf("\n", from);
  return end === -1 ? source.length : end;
}
