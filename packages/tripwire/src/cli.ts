/**
 * The comment tripwire: fails when hand-written source announces a workaround
 * or suppresses a diagnostic without saying why. Run from anywhere inside the
 * repository; `--github` prints workflow annotations instead of plain lines.
 */
import process from "node:process";
import { check, repositoryRoot } from "./tripwire.ts";

const github = process.argv.includes("--github");
const reports = check(repositoryRoot(process.cwd()));

for (const { path, line, message } of reports) {
  process.stdout.write(
    github
      ? `::error file=${path},line=${line},title=Comment tripwire::${message}\n`
      : `${path}:${line}: ${message}\n`,
  );
}
process.exitCode = reports.length === 0 ? 0 : 1;
