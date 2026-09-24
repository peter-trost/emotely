import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { scan } from "./comments.ts";

describe("workaround comments", () => {
  it("flags a TODO in a Dart line comment", () => {
    assert.deepEqual(
      scan("lib/a.dart", "void f() {}\n// TODO: handle later\n"),
      [{ line: 2, rule: "workaround", match: "TODO" }],
    );
  });

  it("ignores the words inside Dart strings, however they are quoted", () => {
    const source = [
      "final a = 'see // TODO';",
      'final b = "a // HACK: in a string";',
      "final c = r'raw // FIXME';",
      "final d = '''",
      "// TODO inside a multi-line string",
      "''';",
      "final e = 'x ${f('// XXX')} y';",
      'final g = "it\'s // TODO";',
    ].join("\n");
    assert.deepEqual(scan("lib/a.dart", source), []);
  });

  it("finds a tag in TypeScript comments of every kind, doc comments too", () => {
    const source = [
      "const a = 1; // FIXME: flaky",
      "/* HACK */",
      "/**",
      " * Returns x. XXX",
      " */",
    ].join("\n");
    assert.deepEqual(
      scan("src/a.ts", source).map(({ line, match }) => [line, match]),
      [
        [1, "FIXME"],
        [2, "HACK"],
        [4, "XXX"],
      ],
    );
  });

  it("ignores TypeScript strings, template literals and regular expressions", () => {
    const source = [
      "const a = `// TODO ${'`'} still // TODO`;",
      "const b = /\\/\\/ TODO/;",
      "const c = x.replace(/[/]TODO/g, '');",
      "const d = `",
      "// TODO in a multi-line template",
      "`;",
      "const e = 4 / 2; // real comment",
    ].join("\n");
    assert.deepEqual(scan("src/a.ts", source), []);
  });

  it("reads a lower-case tag only as a tag, not as prose", () => {
    assert.deepEqual(
      scan("a.ts", "// todo: later\n// the todo list screen\n").map(
        ({ line, match }) => [line, match],
      ),
      [[1, "todo"]],
    );
  });

  it("finds shell comments, but not quotes, heredocs or parameter expansions", () => {
    const source = [
      "#!/usr/bin/env bash",
      'dir="$(mktemp -d "$PREFIX/.setup-XXXXXX")"',
      "echo 'no # TODO here' \"nor # TODO here\"",
      'echo "${#args[@]} $# ${x#TODO}"',
      "cat <<'EOF'",
      "# TODO in a heredoc body",
      "EOF",
      "run # TODO: after code",
    ].join("\n");
    assert.deepEqual(scan("scripts/a.sh", source), [
      { line: 8, rule: "workaround", match: "TODO" },
    ]);
  });

  it("reads a nested Dart block comment to its true end", () => {
    const source = "/* outer /* inner */ still a comment: TODO */ f();\n";
    assert.deepEqual(scan("lib/a.dart", source), [
      { line: 1, rule: "workaround", match: "TODO" },
    ]);
  });

  it("scans only Dart, TypeScript and shell sources", () => {
    assert.deepEqual(scan("README.md", "<!-- TODO -->\n// TODO\n"), []);
  });

  it("flags the phrases that announce a workaround", () => {
    const source = [
      "// Workaround for the picker's layout bug.",
      "// A work-around until the SDK ships the fix.",
      "// Use the cached value for now.",
      "// A temporary fix; revert once upstream lands.",
      "// Temporarily disabled on Android.",
    ].join("\n");
    assert.deepEqual(
      scan("lib/a.dart", source).map(({ line, match }) => [line, match]),
      [
        [1, "Workaround"],
        [2, "work-around"],
        [3, "for now"],
        [4, "temporary"],
        [5, "Temporarily"],
      ],
    );
  });

  it("leaves the same words alone where they describe behavior", () => {
    const source = [
      "// Write the key to a temporary file, then rename it into place.",
      "// Both temporary directories are removed on exit.",
      "// The failure is ours to notice, not the user's to work around.",
      "/// Rate-limited (HTTP 429): too many codes for now.",
      "/// A temporary hold, released when the session ends.",
    ].join("\n");
    assert.deepEqual(scan("lib/a.dart", source), []);
  });

  it("still flags a tag in a documentation comment", () => {
    assert.deepEqual(scan("lib/a.dart", "/// TODO: document\n"), [
      { line: 1, rule: "workaround", match: "TODO" },
    ]);
  });

  it("finds the comment after a string that holds a comment opener", () => {
    assert.deepEqual(scan("lib/a.dart", "final u = 'https://x'; // TODO"), [
      { line: 1, rule: "workaround", match: "TODO" },
    ]);
  });
});

/** The suppressions `scan` flags, as `[line, directive]` pairs. */
function suppressions(path: string, lines: readonly string[]) {
  return scan(path, lines.join("\n"))
    .filter(({ rule }) => rule === "suppression")
    .map(({ line, match }) => [line, match]);
}

describe("suppressions", () => {
  it("flags a bare Dart ignore", () => {
    assert.deepEqual(
      suppressions("lib/a.dart", [
        "void f() {",
        "  // ignore: deprecated_member_use",
        "  old();",
        "  // ignore: a_rule, b_rule",
        "  older();",
        "}",
      ]),
      [
        [2, "ignore: deprecated_member_use"],
        [4, "ignore: a_rule, b_rule"],
      ],
    );
  });

  it("accepts a reason of four or more words on the comment line above", () => {
    assert.deepEqual(
      suppressions("lib/a.dart", [
        "// The picker still builds on material, so the bridge stays.",
        "// ignore: deprecated_member_use",
        "old();",
        "// Needed here.",
        "// ignore: deprecated_member_use",
        "old();",
      ]),
      [[5, "ignore: deprecated_member_use"]],
    );
  });

  it("accepts a reason of four or more words on the same line", () => {
    assert.deepEqual(
      suppressions("lib/a.dart", [
        "old(); // ignore: deprecated_member_use, the bridge still needs it",
        "old(); // ignore: deprecated_member_use -- needed",
      ]),
      [[2, "ignore: deprecated_member_use"]],
    );
  });

  it("wants each directive's own reason: neither code nor another directive counts", () => {
    assert.deepEqual(
      suppressions("lib/a.dart", [
        "// Both rules fire on the classic constructor form here.",
        "// ignore_for_file: use_primary_constructors",
        "// ignore_for_file: unnecessary_type_name_in_constructor",
        "final a = b; // the reason sits beside the code",
        "old(); // ignore: deprecated_member_use",
      ]),
      [
        [3, "ignore_for_file: unnecessary_type_name_in_constructor"],
        [5, "ignore: deprecated_member_use"],
      ],
    );
  });

  it("accepts the reason below a directive on the first line of a file", () => {
    assert.deepEqual(
      suppressions("lib/main.dart", [
        "// coverage:ignore-file",
        "// The launch sequence; the graph it composes is tested elsewhere.",
        "",
        "// coverage:ignore-line",
        "// A reason below does not count away from the first line.",
      ]),
      [[4, "coverage:ignore-line"]],
    );
  });

  it("knows the coverage and complexity markers, and needs no reason to end a range", () => {
    assert.deepEqual(
      suppressions("lib/a.dart", [
        "// coverage:ignore-start",
        "f();",
        "// coverage:ignore-end",
        "// cognitive_complexity:ignore",
        "void g() {}",
        "// A state machine whose branches read best kept together.",
        "// cognitive_complexity:ignore",
        "void h() {}",
        "// cognitive_complexity:ignore_for_file",
      ]),
      [
        [1, "coverage:ignore-start"],
        [4, "cognitive_complexity:ignore"],
        [9, "cognitive_complexity:ignore_for_file"],
      ],
    );
  });

  it("reads the reason after a biome-ignore's colon", () => {
    assert.deepEqual(
      suppressions("src/a.ts", [
        "// biome-ignore lint/security/noSecrets: a gateway error class name, not a secret",
        '"GatewayInvalidRequestError",',
        "// biome-ignore lint/security/noSecrets: ok",
        "x;",
        "// biome-ignore lint/style/noMagicNumbers",
        "y;",
        "// biome-ignore-start lint/style/noMagicNumbers: <explanation>",
        "// biome-ignore-end lint/style/noMagicNumbers",
      ]),
      [
        [3, "biome-ignore lint/security/noSecrets"],
        [5, "biome-ignore lint/style/noMagicNumbers"],
        [7, "biome-ignore-start lint/style/noMagicNumbers"],
      ],
    );
  });

  it("knows TypeScript's own suppressions", () => {
    assert.deepEqual(
      suppressions("src/a.ts", [
        "// @ts-expect-error",
        "f(1);",
        "// @ts-expect-error the fixture is malformed on purpose here",
        "f(2);",
        "/* @ts-ignore */ f(3);",
      ]),
      [
        [1, "@ts-expect-error"],
        [5, "@ts-ignore"],
      ],
    );
  });

  it("knows shellcheck's, with the reason after a second #", () => {
    assert.deepEqual(
      suppressions("scripts/a.sh", [
        "# shellcheck disable=SC2086 # word splitting on $inputs is the point.",
        "git diff $inputs",
        "# shellcheck disable=SC2016",
        "echo '$x'",
      ]),
      [[3, "shellcheck disable=SC2016"]],
    );
  });

  it("does not take a mention of a directive in prose for the directive", () => {
    assert.deepEqual(
      suppressions("lib/a.dart", [
        "// Never add a bare // ignore: here; see biome-ignore too.",
        "final s = '// ignore: x';",
      ]),
      [],
    );
  });
});
