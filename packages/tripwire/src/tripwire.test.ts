import assert from "node:assert/strict";
import { execFileSync, spawnSync } from "node:child_process";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import process from "node:process";
import { after, describe, it } from "node:test";
import { fileURLToPath } from "node:url";
import { check } from "./tripwire.ts";

const cli = join(dirname(fileURLToPath(import.meta.url)), "cli.ts");
const created: string[] = [];

after(() => {
  for (const root of created) {
    rmSync(root, { recursive: true, force: true });
  }
});

/** A git repository holding `tracked`, plus `untracked` left out of the index. */
function repo(
  tracked: Record<string, string>,
  untracked: Record<string, string> = {},
): string {
  const root = mkdtempSync(join(tmpdir(), "tripwire-"));
  created.push(root);
  execFileSync("git", ["init", "--quiet"], { cwd: root });
  const write = (files: Record<string, string>) => {
    for (const [path, content] of Object.entries(files)) {
      mkdirSync(dirname(join(root, path)), { recursive: true });
      writeFileSync(join(root, path), content);
    }
  };
  write(tracked);
  execFileSync("git", ["add", "."], { cwd: root });
  write(untracked);
  return root;
}

describe("check", () => {
  it("reports every tracked hand-written source, with its path", () => {
    const root = repo({
      "apps/mobile/lib/a.dart": "// TODO: handle later\n",
      "apps/agent/src/b.ts": "// ok\n// biome-ignore lint/x/y\nf();\n",
      "scripts/c.sh": "#!/bin/sh\n# FIXME\n",
    });
    const lines = check(root).map(
      ({ path, line, message }) => `${path}:${line}: ${message}`,
    );
    assert.deepEqual(lines, [
      'apps/agent/src/b.ts:2: unexplained suppression "biome-ignore lint/x/y": give its reason in 4 or more words on the same line or on the comment line above',
      'apps/mobile/lib/a.dart:1: workaround comment "TODO": record deferred work in an issue, not a comment',
      'scripts/c.sh:2: workaround comment "FIXME": record deferred work in an issue, not a comment',
    ]);
  });

  it("exempts generated files and anything git does not track", () => {
    const root = repo(
      {
        "lib/a.g.dart": "// ignore: type=lint\n// TODO\n",
        "lib/a.freezed.dart": "// ignore_for_file: type=lint\n",
        "lib/main.server.options.dart": "// ignore_for_file: type=lint\n",
        "lib/mocks.mocks.dart": "// ignore_for_file: type=lint\n",
        "lib/clean.dart": "// Nothing to see here.\n",
      },
      { "lib/scratch.dart": "// TODO\n", "node_modules/x/y.ts": "// TODO\n" },
    );
    assert.deepEqual(check(root), []);
  });
});

describe("the command", () => {
  it("fails with the file, the line and the reason", () => {
    const root = repo({ "lib/a.dart": "void f() {}\n// TODO: handle later\n" });
    const run = spawnSync(process.execPath, [cli], {
      cwd: root,
      encoding: "utf8",
    });
    assert.equal(run.status, 1);
    assert.match(run.stdout, /^lib\/a\.dart:2: workaround comment "TODO"/m);
  });

  it("writes GitHub annotations when asked", () => {
    const root = repo({ "lib/a.dart": "// TODO\n" });
    const run = spawnSync(process.execPath, [cli, "--github"], {
      cwd: root,
      encoding: "utf8",
    });
    assert.match(
      run.stdout,
      /^::error file=lib\/a\.dart,line=1,title=Comment tripwire::workaround comment "TODO"/m,
    );
  });

  it("passes a clean tree, from any directory inside it", () => {
    const root = repo({ "lib/a.dart": "// Nothing deferred.\n" });
    const run = spawnSync(process.execPath, [cli], {
      cwd: join(root, "lib"),
      encoding: "utf8",
    });
    assert.equal(run.status, 0);
  });
});
