/**
 * Peon Ping clone for Pi.
 *
 * - /peon opens a settings panel in interactive mode
 * - /peon install installs the default upstream pack set when no pack is given
 * - pack browsing previews sounds while you move through the list
 * - per-category toggles and silent-window setting
 * - config/state stored in ~/.config/peon-ping/
 */

import { execSync, spawn } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from "node:fs";
import { homedir, platform as osPlatform } from "node:os";
import { basename, join } from "node:path";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { DynamicBorder, getSettingsListTheme, keyHint } from "@mariozechner/pi-coding-agent";
import {
  CancellableLoader,
  Container,
  type Component,
  type SettingItem,
  SelectList,
  SettingsList,
  Spacer,
  Text,
} from "@mariozechner/pi-tui";

type NotifyLevel = "info" | "warning" | "error";
type Platform = "mac" | "linux" | "unknown";

type Category =
  | "session.start"
  | "task.acknowledge"
  | "task.complete"
  | "task.error"
  | "input.required"
  | "resource.limit"
  | "user.spam";

interface PeonConfig {
  default_pack: string;
  volume: number;
  enabled: boolean;
  categories: Record<Category, boolean>;
  annoyed_threshold: number;
  annoyed_window_seconds: number;
  silent_window_seconds: number;
}

interface PeonState {
  paused: boolean;
  last_played: Record<string, string>;
  prompt_timestamps: number[];
  prompt_start_time: number;
  last_stop_time: number;
  session_start_time: number;
}

interface PackManifest {
  name?: string;
  display_name?: string;
  categories?: Record<string, { sounds?: Array<{ file: string; label?: string }> }>;
}

interface RegistryPack {
  name: string;
  source_repo?: string;
  source_ref?: string;
  source_path?: string;
}

interface Registry {
  packs?: RegistryPack[];
}

interface InstalledPack {
  name: string;
  displayName: string;
  path: string;
}

const DATA_DIR = join(homedir(), ".config", "peon-ping");
const CONFIG_PATH = join(DATA_DIR, "config.json");
const STATE_PATH = join(DATA_DIR, "state.json");
const PACKS_DIR = join(DATA_DIR, "packs");

const CATEGORY_LABELS: Record<Category, string> = {
  "session.start": "Session start",
  "task.acknowledge": "Task acknowledge",
  "task.complete": "Task complete",
  "task.error": "Task error",
  "input.required": "Input required",
  "resource.limit": "Resource limit",
  "user.spam": "Rapid prompt spam",
};

const DEFAULT_CONFIG: PeonConfig = {
  default_pack: "peon",
  volume: 0.5,
  enabled: true,
  categories: {
    "session.start": true,
    "task.acknowledge": true,
    "task.complete": true,
    "task.error": true,
    "input.required": true,
    "resource.limit": true,
    "user.spam": true,
  },
  annoyed_threshold: 3,
  annoyed_window_seconds: 10,
  silent_window_seconds: 0,
};

const DEFAULT_STATE: PeonState = {
  paused: false,
  last_played: {},
  prompt_timestamps: [],
  prompt_start_time: 0,
  last_stop_time: 0,
  session_start_time: 0,
};

const DEFAULT_PACK_NAMES = [
  "peon",
  "peasant",
  "glados",
  "sc_kerrigan",
  "sc_battlecruiser",
  "ra2_kirov",
  "dota2_axe",
  "duke_nukem",
  "tf2_engineer",
  "hd2_helldiver",
];

const VOLUME_STEPS = ["10%", "20%", "30%", "40%", "50%", "60%", "70%", "80%", "90%", "100%"];
const SILENT_WINDOW_STEPS = ["0s", "1s", "2s", "3s", "5s", "10s", "15s", "30s"];
const TESTABLE_CATEGORIES = Object.keys(CATEGORY_LABELS) as Category[];

const REGISTRY_URL = "https://peonping.github.io/registry/index.json";
const FALLBACK_REPO = "PeonPing/og-packs";
const FALLBACK_REF = "v1.1.0";

let cachedLinuxPlayer: string | null | undefined;
let currentSoundPid: number | null = null;

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

function ensureDataDirs(): void {
  mkdirSync(DATA_DIR, { recursive: true });
  mkdirSync(PACKS_DIR, { recursive: true });
}

function report(ctx: any, message: string, type: NotifyLevel = "info"): void {
  if (ctx?.hasUI) {
    ctx.ui.notify(message, type);
    return;
  }

  const prefix = type === "error" ? "error" : type === "warning" ? "warn" : "info";
  console.log(`[peon] ${prefix}: ${message}`);
}

function detectPlatform(): Platform {
  const platform = osPlatform();
  if (platform === "darwin") return "mac";
  if (platform === "linux") return "linux";
  return "unknown";
}

function detectLinuxPlayer(): string | null {
  if (cachedLinuxPlayer !== undefined) return cachedLinuxPlayer;

  for (const command of ["pw-play", "paplay", "ffplay", "mpv", "play", "aplay"]) {
    try {
      execSync(`command -v ${command}`, { stdio: "ignore" });
      cachedLinuxPlayer = command;
      return cachedLinuxPlayer;
    } catch {
      // try next player
    }
  }

  cachedLinuxPlayer = null;
  return null;
}

function killPreviousSound(): void {
  if (currentSoundPid === null) return;
  try {
    process.kill(currentSoundPid);
  } catch {
    // ignore stale pid
  }
  currentSoundPid = null;
}

function playFile(file: string, volume: number): boolean {
  const platform = detectPlatform();
  let child;

  killPreviousSound();

  try {
    if (platform === "mac") {
      child = spawn("afplay", ["-v", String(clamp(volume, 0, 1)), file], {
        stdio: "ignore",
        detached: true,
      });
    } else if (platform === "linux") {
      const player = detectLinuxPlayer();
      if (!player) return false;

      switch (player) {
        case "pw-play":
          child = spawn("pw-play", ["--volume", String(clamp(volume, 0, 1)), file], {
            stdio: "ignore",
            detached: true,
          });
          break;
        case "paplay":
          child = spawn("paplay", [`--volume=${Math.round(clamp(volume, 0, 1) * 65536)}`, file], {
            stdio: "ignore",
            detached: true,
          });
          break;
        case "ffplay":
          child = spawn(
            "ffplay",
            [
              "-nodisp",
              "-autoexit",
              "-loglevel",
              "quiet",
              "-volume",
              String(Math.round(clamp(volume, 0, 1) * 100)),
              file,
            ],
            {
              stdio: "ignore",
              detached: true,
            },
          );
          break;
        case "mpv":
          child = spawn(
            "mpv",
            [
              "--really-quiet",
              "--no-video",
              `--volume=${Math.round(clamp(volume, 0, 1) * 100)}`,
              file,
            ],
            {
              stdio: "ignore",
              detached: true,
            },
          );
          break;
        case "play":
          child = spawn("play", ["-q", "-v", String(clamp(volume, 0, 1)), file], {
            stdio: "ignore",
            detached: true,
          });
          break;
        case "aplay":
          child = spawn("aplay", ["-q", file], {
            stdio: "ignore",
            detached: true,
          });
          break;
      }
    }
  } catch {
    return false;
  }

  if (!child) return false;

  child.unref();
  currentSoundPid = child.pid ?? null;
  child.on("exit", () => {
    if (currentSoundPid === child.pid) currentSoundPid = null;
  });
  child.on("error", () => {
    if (currentSoundPid === child.pid) currentSoundPid = null;
  });
  return true;
}

function loadConfig(): PeonConfig {
  try {
    const raw = JSON.parse(readFileSync(CONFIG_PATH, "utf8")) as Record<string, unknown>;
    const migrated = { ...raw };

    if (typeof migrated.active_pack === "string" && typeof migrated.default_pack !== "string") {
      migrated.default_pack = migrated.active_pack;
    }
    delete migrated.active_pack;

    const rawCategories =
      typeof migrated.categories === "object" && migrated.categories !== null
        ? (migrated.categories as Partial<Record<Category, boolean>>)
        : {};

    return {
      ...DEFAULT_CONFIG,
      ...migrated,
      default_pack:
        typeof migrated.default_pack === "string"
          ? migrated.default_pack
          : DEFAULT_CONFIG.default_pack,
      volume:
        typeof migrated.volume === "number" ? clamp(migrated.volume, 0, 1) : DEFAULT_CONFIG.volume,
      enabled: typeof migrated.enabled === "boolean" ? migrated.enabled : DEFAULT_CONFIG.enabled,
      annoyed_threshold:
        typeof migrated.annoyed_threshold === "number"
          ? Math.max(1, Math.round(migrated.annoyed_threshold))
          : DEFAULT_CONFIG.annoyed_threshold,
      annoyed_window_seconds:
        typeof migrated.annoyed_window_seconds === "number"
          ? Math.max(1, Math.round(migrated.annoyed_window_seconds))
          : DEFAULT_CONFIG.annoyed_window_seconds,
      silent_window_seconds:
        typeof migrated.silent_window_seconds === "number"
          ? Math.max(0, Math.round(migrated.silent_window_seconds))
          : DEFAULT_CONFIG.silent_window_seconds,
      categories: {
        ...DEFAULT_CONFIG.categories,
        ...rawCategories,
      },
    };
  } catch {
    return { ...DEFAULT_CONFIG, categories: { ...DEFAULT_CONFIG.categories } };
  }
}

function saveConfig(config: PeonConfig): PeonConfig {
  ensureDataDirs();
  const currentRaw = existsSync(CONFIG_PATH)
    ? (JSON.parse(readFileSync(CONFIG_PATH, "utf8")) as Record<string, unknown>)
    : {};

  const merged = {
    ...currentRaw,
    ...config,
    categories: {
      ...DEFAULT_CONFIG.categories,
      ...(typeof currentRaw.categories === "object" && currentRaw.categories !== null
        ? currentRaw.categories
        : {}),
      ...config.categories,
    },
  };

  delete merged.active_pack;
  writeFileSync(CONFIG_PATH, JSON.stringify(merged, null, 2) + "\n");
  return config;
}

function updateConfig(patch: Partial<PeonConfig>): PeonConfig {
  const current = loadConfig();
  const next: PeonConfig = {
    ...current,
    ...patch,
    categories: {
      ...current.categories,
      ...(patch.categories ?? {}),
    },
  };
  return saveConfig(next);
}

function loadState(): PeonState {
  try {
    const raw = JSON.parse(readFileSync(STATE_PATH, "utf8")) as Partial<PeonState>;
    return {
      ...DEFAULT_STATE,
      ...raw,
      last_played: { ...DEFAULT_STATE.last_played, ...(raw.last_played ?? {}) },
      prompt_timestamps: Array.isArray(raw.prompt_timestamps) ? raw.prompt_timestamps : [],
    };
  } catch {
    return { ...DEFAULT_STATE, last_played: {}, prompt_timestamps: [] };
  }
}

function saveState(state: PeonState): PeonState {
  ensureDataDirs();
  writeFileSync(STATE_PATH, JSON.stringify(state, null, 2) + "\n");
  return state;
}

function loadManifest(packPath: string): PackManifest | null {
  for (const name of ["openpeon.json", "manifest.json"]) {
    const file = join(packPath, name);
    if (!existsSync(file)) continue;

    try {
      return JSON.parse(readFileSync(file, "utf8")) as PackManifest;
    } catch {
      return null;
    }
  }

  return null;
}

function listInstalledPacks(): InstalledPack[] {
  if (!existsSync(PACKS_DIR)) return [];

  const packs: InstalledPack[] = [];
  for (const entry of readdirSync(PACKS_DIR)) {
    const packPath = join(PACKS_DIR, entry);
    const manifest = loadManifest(packPath);
    if (!manifest) continue;

    const name = manifest.name || entry;
    packs.push({
      name,
      displayName: manifest.display_name || name,
      path: packPath,
    });
  }

  return packs.sort((a, b) => a.name.localeCompare(b.name));
}

function findInstalledPack(name: string): InstalledPack | null {
  return listInstalledPacks().find((pack) => pack.name === name) ?? null;
}

function resolveActivePack(config: PeonConfig): { pack: InstalledPack; fallback: boolean } | null {
  const selected = findInstalledPack(config.default_pack);
  if (selected) return { pack: selected, fallback: false };

  const first = listInstalledPacks()[0];
  if (!first) return null;

  return { pack: first, fallback: true };
}

function resolveEndOfTurnCategory(): Category {
  // Successful agent completion should always use the completion bucket.
  // Reserve input.required for actual approval / input prompts.
  return "task.complete";
}

function getAgentEndOutcome(
  messages: Array<{ role?: string; stopReason?: string }>,
): "success" | "error" | "none" {
  for (let i = messages.length - 1; i >= 0; i--) {
    const message = messages[i];
    if (message?.role !== "assistant") continue;
    if (message.stopReason === "stop") return "success";
    if (message.stopReason === "error") return "error";
    return "none";
  }

  return "none";
}

function pickSound(
  category: Category,
  config: PeonConfig,
  state: PeonState,
): { file: string } | null {
  if (!config.categories[category]) return null;

  const resolved = resolveActivePack(config);
  if (!resolved) return null;

  const manifest = loadManifest(resolved.pack.path);
  const sounds = manifest?.categories?.[category]?.sounds ?? [];
  if (sounds.length === 0) return null;

  const previous = state.last_played[category];
  let candidates = sounds;
  if (sounds.length > 1 && previous) {
    const filtered = sounds.filter((sound) => sound.file !== previous);
    if (filtered.length > 0) candidates = filtered;
  }

  const selected = candidates[Math.floor(Math.random() * candidates.length)]!;
  const relative = selected.file.includes("/") ? selected.file : join("sounds", selected.file);
  const fullPath = join(resolved.pack.path, relative);
  if (!existsSync(fullPath)) return null;

  state.last_played[category] = selected.file;
  return {
    file: fullPath,
  };
}

async function fetchRegistry(): Promise<Registry | null> {
  try {
    const response = await fetch(REGISTRY_URL, { signal: AbortSignal.timeout(10000) });
    if (!response.ok) return null;
    return (await response.json()) as Registry;
  } catch {
    return null;
  }
}

async function downloadBinary(url: string, destPath: string): Promise<boolean> {
  try {
    const response = await fetch(url, { signal: AbortSignal.timeout(20000) });
    if (!response.ok) return false;
    const bytes = Buffer.from(await response.arrayBuffer());
    writeFileSync(destPath, bytes);
    return true;
  } catch {
    return false;
  }
}

async function downloadPack(
  packName: string,
  registry: Registry | null,
  onProgress?: (message: string) => void,
): Promise<{ ok: boolean; sounds: number; total: number }> {
  ensureDataDirs();

  const entry = registry?.packs?.find((pack) => pack.name === packName);
  const sourceRepo = entry?.source_repo || FALLBACK_REPO;
  const sourceRef = entry?.source_ref || FALLBACK_REF;
  const sourcePath = entry?.source_path || packName;
  const baseUrl = `https://raw.githubusercontent.com/${sourceRepo}/${sourceRef}/${sourcePath}`;

  const packDir = join(PACKS_DIR, packName);
  const soundsDir = join(packDir, "sounds");
  mkdirSync(soundsDir, { recursive: true });

  onProgress?.(`${packName}: manifest...`);
  const manifestPath = join(packDir, "openpeon.json");
  const manifestOk = await downloadBinary(`${baseUrl}/openpeon.json`, manifestPath);
  if (!manifestOk) {
    onProgress?.(`${packName}: ✗ manifest failed`);
    return { ok: false, sounds: 0, total: 0 };
  }

  const manifest = loadManifest(packDir);
  const files = new Set<string>();
  for (const category of Object.values(manifest?.categories ?? {})) {
    for (const sound of category.sounds ?? []) {
      files.add(basename(sound.file));
    }
  }

  const names = Array.from(files);
  let downloaded = 0;
  for (const name of names) {
    const ok = await downloadBinary(`${baseUrl}/sounds/${name}`, join(soundsDir, name));
    if (ok) downloaded += 1;
    onProgress?.(`${packName}: ${downloaded}/${names.length} sounds`);
  }

  return { ok: downloaded > 0, sounds: downloaded, total: names.length };
}

function previewPack(packName: string): void {
  const config = loadConfig();
  const pack = findInstalledPack(packName);
  if (!pack) return;

  const manifest = loadManifest(pack.path);
  if (!manifest?.categories) return;

  const category = manifest.categories["session.start"] || Object.values(manifest.categories)[0];
  const sounds = category?.sounds ?? [];
  if (sounds.length === 0) return;

  const selected = sounds[Math.floor(Math.random() * sounds.length)]!;
  const file = selected.file.includes("/")
    ? join(pack.path, selected.file)
    : join(pack.path, "sounds", selected.file);

  if (existsSync(file)) {
    playFile(file, config.volume);
  }
}

function soundStatus(config: PeonConfig, state: PeonState): string {
  if (!config.enabled) return "disabled";
  if (state.paused) return "paused";
  return "active";
}

function formatStatus(config: PeonConfig, state: PeonState): string {
  const packs = listInstalledPacks();
  const active = resolveActivePack(config);
  const platform = detectPlatform();
  const player =
    platform === "linux" ? (detectLinuxPlayer() ?? "none") : platform === "mac" ? "afplay" : "none";
  const packText = active
    ? `${active.pack.name}${active.fallback ? " (fallback)" : ""}`
    : `${config.default_pack} (missing)`;

  return [
    `status=${soundStatus(config, state)}`,
    `pack=${packText}`,
    `installed=${packs.length}`,
    `player=${player}`,
    `volume=${Math.round(config.volume * 100)}%`,
  ].join(" · ");
}

function createPackPickerSubmenu(
  currentPack: string,
  packs: InstalledPack[],
  onSelect: (name: string) => void,
  onCancel: () => void,
): Component {
  const slTheme = getSettingsListTheme();
  const items = packs.map((pack) => ({
    value: pack.name,
    label: `${pack.name === currentPack ? "▶ " : "  "}${pack.displayName}`,
    description: pack.name,
  }));

  const list = new SelectList(items, Math.min(items.length, 12), {
    selectedPrefix: (text: string) => slTheme.label(text, true),
    selectedText: (text: string) => slTheme.label(text, true),
    description: slTheme.description,
    scrollInfo: slTheme.hint,
    noMatch: (text: string) => slTheme.label(text, false),
  });

  const currentIndex = packs.findIndex((pack) => pack.name === currentPack);
  if (currentIndex >= 0) list.setSelectedIndex(currentIndex);

  list.onSelect = (item) => onSelect(item.value);
  list.onCancel = () => {
    killPreviousSound();
    onCancel();
  };
  list.onSelectionChange = (item) => previewPack(item.value);

  return {
    render(width: number) {
      return list.render(width);
    },
    invalidate() {
      list.invalidate();
    },
    handleInput(data: string) {
      list.handleInput(data);
    },
  };
}

function buildSettingsItems(): SettingItem[] {
  const config = loadConfig();
  const state = loadState();
  const packs = listInstalledPacks();
  const activePack = packs.find((pack) => pack.name === config.default_pack);

  const items: SettingItem[] = [
    {
      id: "sounds",
      label: "Sounds",
      description: "Master sound state",
      currentValue: soundStatus(config, state),
      values: ["active", "paused", "disabled"],
    },
    {
      id: "pack",
      label: "Sound pack",
      description: `${packs.length} installed`,
      currentValue: activePack?.displayName || config.default_pack,
      submenu: (_current: string, done: (value?: string) => void) => {
        if (packs.length === 0) {
          done();
          return {
            render: () => ["No packs installed"],
            invalidate() {},
            handleInput() {},
          } as Component;
        }

        return createPackPickerSubmenu(
          config.default_pack,
          packs,
          (name) => {
            const nextConfig = loadConfig();
            nextConfig.default_pack = name;
            saveConfig(nextConfig);
            const pack = packs.find((entry) => entry.name === name);
            done(pack?.displayName || name);
          },
          () => done(),
        );
      },
    },
    {
      id: "volume",
      label: "Volume",
      currentValue: `${Math.round(config.volume * 100)}%`,
      values: VOLUME_STEPS,
    },
    {
      id: "silent_window_seconds",
      label: "Silent window",
      description: "Suppress the end-of-turn sound for very short tasks",
      currentValue: `${config.silent_window_seconds}s`,
      values: SILENT_WINDOW_STEPS,
    },
  ];

  for (const [category, label] of Object.entries(CATEGORY_LABELS)) {
    items.push({
      id: `cat:${category}`,
      label,
      currentValue: config.categories[category as Category] ? "on" : "off",
      values: ["on", "off"],
    });
  }

  items.push({
    id: "preview",
    label: "Preview sound",
    currentValue: "▶",
    values: ["▶"],
  });

  return items;
}

async function runInstallInteractive(
  packNames: string[],
  ctx: any,
  onInstallStart: () => void,
  onInstallEnd: () => void,
): Promise<void> {
  const result: { installed: number; total: number } | null = await ctx.ui.custom(
    (
      tui: any,
      theme: any,
      _kb: any,
      done: (value: { installed: number; total: number } | null) => void,
    ) => {
      const container = new Container();
      container.addChild(new DynamicBorder((text: string) => theme.fg("border", text)));

      const loader = new CancellableLoader(
        tui,
        (text: string) => theme.fg("accent", text),
        (text: string) => theme.fg("muted", text),
        "Fetching pack registry...",
      );
      container.addChild(loader);
      container.addChild(new Spacer(1));
      container.addChild(new Text(keyHint("selectCancel", "cancel"), 1, 0));
      container.addChild(new Spacer(1));
      container.addChild(new DynamicBorder((text: string) => theme.fg("border", text)));

      loader.onAbort = () => done(null);

      const doInstall = async () => {
        onInstallStart();
        const registry = await fetchRegistry();
        if (loader.aborted) return;

        const names = packNames.length > 0 ? packNames : DEFAULT_PACK_NAMES;
        let installed = 0;

        for (let i = 0; i < names.length; i++) {
          if (loader.aborted) break;
          const name = names[i]!;
          loader.setMessage(`[${i + 1}/${names.length}] ${name}: downloading...`);

          const result = await downloadPack(name, registry, (message) => {
            if (!loader.aborted) loader.setMessage(`[${i + 1}/${names.length}] ${message}`);
          });
          if (result.ok) installed += 1;
        }

        if (installed > 0) {
          const config = loadConfig();
          if (!findInstalledPack(config.default_pack)) {
            config.default_pack = names[0]!;
            saveConfig(config);
          }
        }

        done({ installed, total: names.length });
      };

      doInstall()
        .catch(() => done(null))
        .finally(() => {
          onInstallEnd();
        });

      return container;
    },
  );

  if (result) {
    report(
      ctx,
      `peon-ping: installed ${result.installed}/${result.total} packs`,
      result.installed > 0 ? "info" : "error",
    );
  } else {
    report(ctx, "peon-ping: install cancelled", "info");
  }
}

async function runInstallCli(packNames: string[], ctx: any): Promise<void> {
  const names = packNames.length > 0 ? packNames : DEFAULT_PACK_NAMES;
  const registry = await fetchRegistry();
  report(ctx, `Installing ${names.join(", ")}...`);

  let installed = 0;
  for (const name of names) {
    const result = await downloadPack(name, registry);
    if (result.ok) {
      installed += 1;
      report(ctx, `Installed ${name} (${result.sounds}/${result.total} sounds)`);
    } else {
      report(ctx, `Failed to install ${name}`, "error");
    }
  }

  if (installed > 0) {
    const config = loadConfig();
    if (!findInstalledPack(config.default_pack)) {
      config.default_pack = names[0]!;
      saveConfig(config);
    }
  }

  report(
    ctx,
    `peon-ping: installed ${installed}/${names.length} packs`,
    installed > 0 ? "info" : "error",
  );
}

function createSettingsPanel(
  tui: any,
  _theme: any,
  _kb: any,
  done: (value: undefined) => void,
): Component {
  const container = new Container();
  container.addChild(new DynamicBorder((text: string) => text));

  const settingsList = new SettingsList(
    buildSettingsItems(),
    Math.min(buildSettingsItems().length + 2, 18),
    getSettingsListTheme(),
    (id, newValue) => {
      if (id === "sounds") {
        const config = loadConfig();
        const state = loadState();

        if (newValue === "disabled") {
          config.enabled = false;
          state.paused = false;
        } else if (newValue === "paused") {
          config.enabled = true;
          state.paused = true;
        } else {
          config.enabled = true;
          state.paused = false;
        }

        saveConfig(config);
        saveState(state);
      } else if (id === "volume") {
        const config = loadConfig();
        config.volume = parseInt(newValue, 10) / 100;
        saveConfig(config);
      } else if (id === "silent_window_seconds") {
        const config = loadConfig();
        config.silent_window_seconds = parseInt(newValue, 10);
        saveConfig(config);
      } else if (id.startsWith("cat:")) {
        const config = loadConfig();
        const category = id.slice(4) as Category;
        config.categories[category] = newValue === "on";
        saveConfig(config);
      } else if (id === "preview") {
        const config = loadConfig();
        const state = loadState();
        const sound = pickSound("session.start", config, state);
        if (sound) {
          playFile(sound.file, config.volume);
          saveState(state);
        }
      }
    },
    () => done(undefined),
  );

  container.addChild(settingsList);
  container.addChild(new DynamicBorder((text: string) => text));

  return {
    render(width: number) {
      return container.render(width);
    },
    invalidate() {
      container.invalidate();
    },
    handleInput(data: string) {
      settingsList.handleInput?.(data);
      tui.requestRender();
    },
  };
}

export default function (pi: ExtensionAPI) {
  ensureDataDirs();

  let warnedMissingPacks = false;
  let warnedMissingPlayer = false;
  let warnedFallbackPack = false;
  let installing = false;

  function maybeWarnAboutSetup(ctx: any, config: PeonConfig): void {
    const packs = listInstalledPacks();

    if (packs.length === 0 && !warnedMissingPacks) {
      warnedMissingPacks = true;
      report(ctx, "peon-ping: no sound packs installed. Run /peon install", "warning");
    }

    if (detectPlatform() === "linux" && !detectLinuxPlayer() && !warnedMissingPlayer) {
      warnedMissingPlayer = true;
      report(ctx, "peon-ping: no supported audio player found", "warning");
    }

    const active = resolveActivePack(config);
    if (active?.fallback && !warnedFallbackPack) {
      warnedFallbackPack = true;
      report(
        ctx,
        `peon-ping: using installed pack ${active.pack.name}. Run /peon pack ${active.pack.name} to make it default`,
        "warning",
      );
    }
  }

  function playCategorySound(
    category: Category,
    ctx: any,
    options?: { ignoreUi?: boolean },
  ): boolean {
    if (installing) return false;
    if (!options?.ignoreUi && !ctx.hasUI) return false;

    const config = loadConfig();
    const state = loadState();

    if (!config.enabled || state.paused || !config.categories[category]) return false;

    maybeWarnAboutSetup(ctx, config);
    if (detectPlatform() === "linux" && !detectLinuxPlayer()) return false;
    if (detectPlatform() === "unknown") return false;

    const sound = pickSound(category, config, state);
    if (!sound) return false;

    saveState(state);
    return playFile(sound.file, config.volume);
  }

  pi.on("session_start", async (_event, ctx) => {
    warnedMissingPacks = false;
    warnedMissingPlayer = false;
    warnedFallbackPack = false;

    const config = loadConfig();
    const state = loadState();
    state.session_start_time = Date.now();
    state.prompt_start_time = 0;
    state.prompt_timestamps = [];
    saveState(state);

    maybeWarnAboutSetup(ctx, config);
    playCategorySound("session.start", ctx);
  });

  pi.on("agent_start", async (_event, ctx) => {
    const config = loadConfig();
    const state = loadState();
    const now = Date.now();
    const windowMs = config.annoyed_window_seconds * 1000;

    state.prompt_start_time = now;
    state.prompt_timestamps = state.prompt_timestamps.filter(
      (timestamp) => now - timestamp < windowMs,
    );
    state.prompt_timestamps.push(now);
    saveState(state);

    if (state.prompt_timestamps.length >= config.annoyed_threshold) {
      playCategorySound("user.spam", ctx);
    } else {
      playCategorySound("task.acknowledge", ctx);
    }
  });

  // Tool-level errors are often recoverable during normal agent work
  // (for example, probing commands or searches with no matches), so
  // do not map them to the user-facing task.error sound.

  pi.on("agent_end", async (event, ctx) => {
    const config = loadConfig();
    const state = loadState();
    const now = Date.now();
    const outcome = getAgentEndOutcome(
      event.messages as Array<{ role?: string; stopReason?: string }>,
    );
    const promptStartTime = state.prompt_start_time;

    state.prompt_start_time = 0;
    saveState(state);

    if (outcome === "error") {
      playCategorySound("task.error", ctx);
      return;
    }

    if (outcome !== "success") return;

    const silentMs = config.silent_window_seconds * 1000;
    if (silentMs > 0 && promptStartTime > 0 && now - promptStartTime < silentMs) {
      return;
    }

    if (now - state.last_stop_time < 5000) return;
    state.last_stop_time = now;
    saveState(state);

    const endOfTurnCategory = resolveEndOfTurnCategory();
    playCategorySound(endOfTurnCategory, ctx);
  });

  pi.registerCommand("peon", {
    description: "peon-ping settings and pack management",
    handler: async (args, ctx) => {
      const input = (args || "").trim();
      const parts = input.length > 0 ? input.split(/\s+/) : [];
      const command = parts[0] || "";
      const rest = parts.slice(1);
      const config = loadConfig();
      const state = loadState();

      if (command === "" || command === "settings") {
        if (!ctx.hasUI) {
          report(ctx, formatStatus(config, state));
          return;
        }

        if (listInstalledPacks().length === 0) {
          const ok = await ctx.ui.confirm(
            "peon-ping",
            "No sound packs installed. Download the default upstream packs now?",
          );
          if (ok) {
            await runInstallInteractive(
              [],
              ctx,
              () => {
                installing = true;
              },
              () => {
                installing = false;
              },
            );
          }
          return;
        }

        await ctx.ui.custom<void>(createSettingsPanel);
        return;
      }

      if (command === "install") {
        const packNames = rest.length > 0 ? rest : DEFAULT_PACK_NAMES;
        if (ctx.hasUI) {
          await runInstallInteractive(
            packNames,
            ctx,
            () => {
              installing = true;
            },
            () => {
              installing = false;
            },
          );
        } else {
          installing = true;
          try {
            await runInstallCli(packNames, ctx);
          } finally {
            installing = false;
          }
        }
        return;
      }

      if (command === "status") {
        report(ctx, formatStatus(config, state));
        return;
      }

      if (command === "list") {
        const packs = listInstalledPacks();
        if (packs.length === 0) {
          report(ctx, "Installed packs: none");
        } else {
          report(ctx, `Installed packs: ${packs.map((pack) => pack.name).join(", ")}`);
        }
        return;
      }

      if (command === "pack") {
        const packName = rest[0];
        if (!packName) {
          const packs = listInstalledPacks();
          report(ctx, `Installed packs: ${packs.map((pack) => pack.name).join(", ") || "none"}`);
          return;
        }

        if (!findInstalledPack(packName)) {
          report(ctx, `Pack ${packName} is not installed. Run /peon install ${packName}`, "error");
          return;
        }

        const nextConfig = updateConfig({ default_pack: packName });
        report(ctx, `Active pack: ${nextConfig.default_pack}`);
        return;
      }

      if (command === "volume") {
        const rawValue = rest[0];
        if (!rawValue) {
          report(ctx, `Volume: ${Math.round(config.volume * 100)}%`);
          return;
        }

        const parsed = Number(rawValue.replace(/%$/, ""));
        if (Number.isNaN(parsed)) {
          report(ctx, "Volume must be a number like 70 or 0.7", "error");
          return;
        }

        const normalized = parsed > 1 ? parsed / 100 : parsed;
        const nextConfig = updateConfig({ volume: clamp(normalized, 0, 1) });
        report(ctx, `Volume: ${Math.round(nextConfig.volume * 100)}%`);
        return;
      }

      if (command === "on" || command === "enable") {
        const nextConfig = updateConfig({ enabled: true });
        const nextState = loadState();
        nextState.paused = false;
        saveState(nextState);
        report(ctx, `peon-ping enabled (${soundStatus(nextConfig, nextState)})`);
        return;
      }

      if (command === "off" || command === "disable") {
        const nextConfig = updateConfig({ enabled: false });
        const nextState = loadState();
        nextState.paused = false;
        saveState(nextState);
        killPreviousSound();
        report(ctx, `peon-ping disabled (${soundStatus(nextConfig, nextState)})`);
        return;
      }

      if (command === "pause") {
        const nextState = loadState();
        nextState.paused = true;
        saveState(nextState);
        report(ctx, "peon-ping paused");
        return;
      }

      if (command === "resume") {
        const nextConfig = updateConfig({ enabled: true });
        const nextState = loadState();
        nextState.paused = false;
        saveState(nextState);
        report(ctx, `peon-ping resumed (${soundStatus(nextConfig, nextState)})`);
        return;
      }

      if (command === "test") {
        const category = (rest[0] || resolveEndOfTurnCategory()) as Category;
        if (!TESTABLE_CATEGORIES.includes(category)) {
          report(ctx, `Unknown category. Try: ${TESTABLE_CATEGORIES.join(", ")}`, "error");
          return;
        }

        const played = playCategorySound(category, ctx, { ignoreUi: true });
        report(
          ctx,
          played ? `Played ${category}` : `Could not play ${category}; run /peon status`,
          played ? "info" : "warning",
        );
        return;
      }

      if (command === "help") {
        report(
          ctx,
          "Usage: /peon [status|install [pack...]|list|pack <name>|volume <0-100>|on|off|pause|resume|test [category]|settings]",
        );
        return;
      }

      report(ctx, "Unknown /peon command. Run /peon help", "error");
    },
  });
}
