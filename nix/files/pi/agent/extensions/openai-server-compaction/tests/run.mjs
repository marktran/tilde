#!/usr/bin/env node
import { execFileSync, spawnSync } from "node:child_process";
import {
  copyFileSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readdirSync,
  rmSync,
  symlinkSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const extensionRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const workspace = mkdtempSync(join(tmpdir(), "pi-openai-compaction-test-"));

function npmGlobalRoot() {
  try {
    return execFileSync("npm", ["root", "-g"], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    }).trim();
  } catch {
    return undefined;
  }
}

function findPackage(packageName, roots) {
  const segments = packageName.split("/");
  for (const root of roots) {
    if (!root) continue;
    const candidate = join(root, ...segments);
    if (existsSync(join(candidate, "package.json"))) return candidate;
  }
  throw new Error(`Unable to locate ${packageName}; install Pi before running this test`);
}

function linkDirectory(target, destination) {
  mkdirSync(dirname(destination), { recursive: true });
  symlinkSync(target, destination, "dir");
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: workspace,
    encoding: "utf8",
    stdio: "inherit",
    ...options,
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(`${command} exited with status ${String(result.status)}`);
  }
}

try {
  for (const name of readdirSync(extensionRoot)) {
    if (name.endsWith(".ts")) copyFileSync(join(extensionRoot, name), join(workspace, name));
  }
  mkdirSync(join(workspace, "tests"), { recursive: true });
  copyFileSync(
    join(extensionRoot, "tests", "offline.test.mjs"),
    join(workspace, "tests", "offline.test.mjs"),
  );

  const globalRoot = npmGlobalRoot();
  const initialRoots = [join(extensionRoot, "node_modules"), globalRoot];
  const codingAgent = findPackage("@earendil-works/pi-coding-agent", initialRoots);
  const roots = [...initialRoots, join(codingAgent, "node_modules")];

  for (const packageName of [
    "@earendil-works/pi-coding-agent",
    "@earendil-works/pi-agent-core",
    "@earendil-works/pi-ai",
  ]) {
    const target = findPackage(packageName, roots);
    linkDirectory(target, join(workspace, "node_modules", ...packageName.split("/")));
  }

  const nodeTypes = roots
    .map((root) => root && join(root, "@types"))
    .find((candidate) => candidate && existsSync(join(candidate, "node", "package.json")));
  if (nodeTypes) linkDirectory(nodeTypes, join(workspace, "node_modules", "@types"));

  writeFileSync(
    join(workspace, "tsconfig.json"),
    `${JSON.stringify(
      {
        compilerOptions: {
          allowImportingTsExtensions: true,
          module: "NodeNext",
          moduleResolution: "NodeNext",
          noEmit: true,
          skipLibCheck: true,
          strict: true,
          target: "ES2022",
          types: ["node"],
        },
        include: ["*.ts"],
      },
      null,
      2,
    )}\n`,
  );

  const tscProbe = spawnSync("tsc", ["--version"], { encoding: "utf8" });
  if (!tscProbe.error && tscProbe.status === 0) {
    run("tsc", ["--noEmit"]);
  } else {
    process.stderr.write("warning: tsc not found; skipping static typecheck\n");
  }

  run(
    process.execPath,
    ["--experimental-strip-types", "--test", "tests/offline.test.mjs"],
    { env: { ...process.env, CODEX_HOME: join(workspace, "codex-home") } },
  );
} finally {
  rmSync(workspace, { recursive: true, force: true });
}
