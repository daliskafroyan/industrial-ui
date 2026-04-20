import { existsSync } from "node:fs";
import { join } from "node:path";
import process from "node:process";

function resolveBiomeCommand() {
  const localBiome = join(
    process.cwd(),
    "node_modules",
    ".bin",
    process.platform === "win32" ? "biome.cmd" : "biome",
  );

  if (existsSync(localBiome)) {
    return `"${localBiome}"`;
  }

  if (process.env.PATH?.includes("bun")) {
    return "bunx biome";
  }

  return "npx --no-install biome";
}

const biomeCheckCommand = `${resolveBiomeCommand()} check --write --no-errors-on-unmatched`;

export default {
  "**/*.{js,ts,jsx,tsx,md,mdx,json}": () => [biomeCheckCommand],
};
