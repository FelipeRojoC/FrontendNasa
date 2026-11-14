// Start the official Runpod MCP server (local mode).
// Reads RUNPOD_API_KEY from the git-ignored `.env` at the repo root (or from the environment)
// and passes only that variable to the server, not the rest of `.env`.
import { spawn } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { parseEnv } from "node:util";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const envFile = path.join(root, ".env");

let apiKey = process.env.RUNPOD_API_KEY;
if (!apiKey && existsSync(envFile)) {
  apiKey = parseEnv(readFileSync(envFile, "utf8")).RUNPOD_API_KEY;
}
if (!apiKey) {
  console.error(`RUNPOD_API_KEY is not set. Add it to ${envFile}.`);
  process.exit(2);
}

const child = spawn("npx", ["-y", "@runpod/mcp-server@4.12.0"], {
  stdio: "inherit",
  shell: process.platform === "win32",
  env: { ...process.env, RUNPOD_API_KEY: apiKey },
});
child.on("exit", (code) => process.exit(code ?? 1));
