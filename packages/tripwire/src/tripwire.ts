import { execFileSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { type Finding, REASON_WORDS, scan } from "./comments.ts";

export type Report = { path: string; line: number; message: string };

const SOURCE = /\.(?:dart|[cm]?[jt]s|sh)$/;
// Generated code answers to its generator, not to this rule.
const GENERATED = /\.(?:g|freezed|options|mocks)\.dart$/;

/**
 * Every finding in the hand-written sources git tracks under `root`, in path
 * order. Build output, dependencies and scratch files are never tracked, so
 * they are never read; nor is a tracked file already deleted from the disk.
 */
export function check(root: string): Report[] {
  return trackedFiles(root)
    .filter((path) => SOURCE.test(path) && !GENERATED.test(path))
    .filter((path) => existsSync(join(root, path)))
    .flatMap((path) =>
      scan(path, readFileSync(join(root, path), "utf8")).map((finding) => ({
        path,
        line: finding.line,
        message: messageFor(finding),
      })),
    );
}

export function repositoryRoot(directory: string): string {
  return execFileSync("git", ["rev-parse", "--show-toplevel"], {
    cwd: directory,
    encoding: "utf8",
  }).trim();
}

function trackedFiles(root: string): string[] {
  return execFileSync("git", ["ls-files", "-z"], {
    cwd: root,
    encoding: "utf8",
  })
    .split("\0")
    .filter((path) => path !== "");
}

function messageFor({ rule, match }: Finding): string {
  return rule === "workaround"
    ? `workaround comment "${match}": record deferred work in an issue, not a comment`
    : `unexplained suppression "${match}": give its reason in ${REASON_WORDS} or more words on the same line or on the comment line above`;
}
