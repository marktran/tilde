/**
 * Web Search Extension
 *
 * Registers a `web_search` tool backed by the Exa search API
 * (POST https://api.exa.ai/search).
 *
 * Results always include query-relevant highlights, which is the token-cheap
 * shape Exa recommends for agent workflows; full page text is opt-in.
 *
 * Credentials: read from pi's own credential store (~/.pi/agent/auth.json)
 * under the provider id `web-search`, e.g.
 *
 *   "web-search": { "type": "api_key", "key": "<literal key>" }
 *   "web-search": { "type": "api_key", "key": "!op read op://Vault/Item/credential" }
 *
 * Until a real key is stored, the entry holds REPLACE_WITH_EXA_API_KEY, which
 * is treated as unset so the tool reports a setup error instead of a 401.
 *
 * pi never enumerates unknown provider ids in its UI, and auth.json writes are
 * per-provider merges under a file lock, so this entry survives /login and
 * OAuth refreshes. `EXA_API_KEY` is used as a fallback when no entry exists.
 *
 * Note: imports use the current `@earendil-works/*` package names. Older
 * extensions in this directory use the legacy `@mariozechner/*` aliases, which
 * pi still maps to the same bundled modules.
 */

import { execSync } from "node:child_process";
import { StringEnum } from "@earendil-works/pi-ai";
import { type ExtensionAPI, readStoredCredential } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const AUTH_PROVIDER_ID = "web-search";
const ENV_FALLBACK = "EXA_API_KEY";
/** Stub value in auth.json; treated as "not configured" so errors stay actionable. */
const PLACEHOLDER_KEY = "REPLACE_WITH_EXA_API_KEY";
const SEARCH_URL = "https://api.exa.ai/search";
const DEFAULT_NUM_RESULTS = 5;
const DEFAULT_TIMEOUT_MS = 60_000;
const FULL_TEXT_MAX_CHARACTERS = 4_000;
const ENV_VAR_NAME_RE = /^[A-Za-z_][A-Za-z0-9_]*$/;
const ENV_VAR_PREFIX_RE = /^[A-Za-z_][A-Za-z0-9_]*/;

/** Exa search types. `auto` balances quality/latency; `deep` does multi-step research. */
const MODES = { auto: "auto", fast: "fast", deep: "deep" } as const;

type Mode = keyof typeof MODES;

/**
 * `deep` only synthesizes an answer when an outputSchema is supplied — without
 * one it is just a slower, pricier result list. Verified against the API.
 */
const DEEP_SYSTEM_PROMPT =
  "Prefer official documentation, release notes, and primary sources. Be concise and factual, and note version numbers and dates where relevant.";
const DEEP_OUTPUT_SCHEMA = {
  type: "text",
  description: "A concise, factual answer to the query, citing specific versions, dates, and details.",
} as const;

interface ExaResult {
  title?: string;
  url?: string;
  publishedDate?: string;
  author?: string;
  text?: string;
  highlights?: string[];
  summary?: string;
}

interface ExaResponse {
  requestId?: string;
  searchType?: string;
  results?: ExaResult[];
  output?: {
    content?: unknown;
    grounding?: { field?: string; citations?: { url?: string; title?: string }[]; confidence?: string }[];
  };
  costDollars?: { total?: number };
  error?: string;
}

/**
 * Mirror of pi's internal `resolveConfigValue()` template handling: `$VAR` and
 * `${VAR}` interpolate from the environment, `$$` and `$!` are escapes.
 * Returns undefined when a referenced variable is unset.
 */
function resolveTemplate(value: string): string | undefined {
  let out = "";
  let index = 0;

  while (index < value.length) {
    const dollar = value.indexOf("$", index);
    if (dollar < 0) {
      out += value.slice(index);
      break;
    }
    out += value.slice(index, dollar);

    const next = value[dollar + 1];
    if (next === "$" || next === "!") {
      out += next;
      index = dollar + 2;
      continue;
    }

    if (next === "{") {
      const end = value.indexOf("}", dollar + 2);
      if (end < 0) {
        out += "$";
        index = dollar + 1;
        continue;
      }
      const name = value.slice(dollar + 2, end);
      if (!ENV_VAR_NAME_RE.test(name)) {
        out += value.slice(dollar, end + 1);
        index = end + 1;
        continue;
      }
      const resolved = process.env[name];
      if (resolved === undefined) return undefined;
      out += resolved;
      index = end + 1;
      continue;
    }

    const match = value.slice(dollar + 1).match(ENV_VAR_PREFIX_RE);
    if (!match) {
      out += "$";
      index = dollar + 1;
      continue;
    }
    const resolved = process.env[match[0]];
    if (resolved === undefined) return undefined;
    out += resolved;
    index = dollar + 1 + match[0].length;
  }

  return out;
}

function runKeyCommand(command: string): string {
  let stdout: string;
  try {
    stdout = execSync(command, { encoding: "utf-8", timeout: 15_000, stdio: ["ignore", "pipe", "pipe"] });
  } catch (error) {
    const stderr = (error as { stderr?: string }).stderr?.trim();
    throw new Error(
      `web_search: API key command failed: ${command}${stderr ? `\n${stderr}` : ""}\n` +
        `If this is a 1Password reference, enable the desktop app's CLI integration ` +
        `(Settings -> Developer -> Integrate with 1Password CLI) or store the literal key instead.`,
    );
  }
  const key = stdout.trim();
  if (!key) throw new Error(`web_search: API key command produced no output: ${command}`);
  return key;
}

/** Resolved once per pi process, matching pi's own command-result caching. */
let cachedApiKey: string | undefined;

function resolveApiKey(): string {
  if (cachedApiKey) return cachedApiKey;

  const credential = readStoredCredential(AUTH_PROVIDER_ID);
  const stored = credential?.type === "api_key" ? credential.key?.trim() : undefined;

  let key: string | undefined;
  if (stored && stored !== PLACEHOLDER_KEY) {
    key = stored.startsWith("!") ? runKeyCommand(stored.slice(1)) : resolveTemplate(stored);
  }
  key ??= process.env[ENV_FALLBACK]?.trim();
  if (key === PLACEHOLDER_KEY) key = undefined;

  if (!key) {
    const action = stored === PLACEHOLDER_KEY ? `Replace the ${PLACEHOLDER_KEY} placeholder` : "Add a key";
    throw new Error(
      `web_search: no Exa API key. ${action} in ~/.pi/agent/auth.json under ` +
        `"${AUTH_PROVIDER_ID}".key (get one at https://dashboard.exa.ai/api-keys). ` +
        `A leading "!" runs the value as a shell command; ${ENV_FALLBACK} is also honored.`,
    );
  }

  cachedApiKey = key;
  return key;
}

function truncate(value: string, max: number): string {
  const collapsed = value.replace(/\s+/g, " ").trim();
  return collapsed.length > max ? `${collapsed.slice(0, max - 1)}…` : collapsed;
}

function formatResults(payload: ExaResponse, fullText: boolean): string {
  const results = payload.results ?? [];
  if (results.length === 0) return "No results.";

  const lines: string[] = [];

  const synthesized = payload.output?.content;
  if (synthesized) {
    const rendered = typeof synthesized === "string" ? synthesized : JSON.stringify(synthesized, null, 2);
    lines.push("## Synthesized answer", rendered.trim(), "");

    // Synthesized text uses [n] markers that index into this citation list.
    const grounding = payload.output?.grounding ?? [];
    const citations = (grounding.find((entry) => entry.field === "content") ?? grounding[0])?.citations ?? [];
    if (citations.length > 0) {
      lines.push("Citations (the [n] markers above refer to these):");
      citations.forEach((citation, position) => {
        const title = citation.title?.trim();
        lines.push(`[${position + 1}] ${title ? `${title} — ` : ""}${citation.url ?? "(no url)"}`);
      });
      lines.push("");
    }
  }

  results.forEach((result, position) => {
    const title = result.title?.trim() || "(untitled)";
    const meta = [
      result.publishedDate ? result.publishedDate.slice(0, 10) : undefined,
      result.author?.trim() || undefined,
    ].filter(Boolean);

    lines.push(`${position + 1}. ${title}`);
    lines.push(`   ${result.url ?? "(no url)"}${meta.length > 0 ? `  ·  ${meta.join("  ·  ")}` : ""}`);

    for (const highlight of result.highlights ?? []) {
      const text = truncate(highlight, 500);
      if (text) lines.push(`   > ${text}`);
    }

    if (fullText && result.text) {
      lines.push("");
      lines.push(truncate(result.text, FULL_TEXT_MAX_CHARACTERS));
    }

    lines.push("");
  });

  const footer = [
    payload.searchType ? `type=${payload.searchType}` : undefined,
    `${results.length} result${results.length === 1 ? "" : "s"}`,
    typeof payload.costDollars?.total === "number" ? `cost=$${payload.costDollars.total.toFixed(4)}` : undefined,
  ].filter(Boolean);
  lines.push(`(${footer.join(" · ")})`);

  return lines.join("\n").trim();
}

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "web_search",
    label: "Web Search",
    description:
      "Search the live web via Exa. Returns ranked results with query-relevant excerpts from each page. " +
      "Use for current information, external documentation, release notes, or anything not in the local repo.",
    promptSnippet: "Search the live web and return ranked URLs with relevant excerpts",
    promptGuidelines: [
      "Use web_search instead of guessing when a question depends on current information, external docs, library/API details, or versions.",
      "Cite the URLs web_search returns so claims can be verified.",
      "Set web_search fullText only when excerpts are not enough; it returns far more tokens.",
    ],
    parameters: Type.Object({
      query: Type.String({
        description: "Natural language search query. Long, semantically rich descriptions work well.",
      }),
      mode: Type.Optional(
        StringEnum(Object.keys(MODES) as Mode[], {
          description:
            "auto (default, ~1s, best for most queries), fast (~450ms, lower quality), " +
            "deep (4-15s, multi-step research that also returns a synthesized, cited answer; " +
            "use for broad questions, not simple lookups).",
          default: "auto",
        }),
      ),
      numResults: Type.Optional(
        Type.Integer({ minimum: 1, maximum: 25, description: `Results to return (default ${DEFAULT_NUM_RESULTS}).` }),
      ),
      includeDomains: Type.Optional(
        Type.Array(Type.String(), {
          description: 'Restrict to these domains or path prefixes, e.g. ["docs.python.org", "exa.ai/blog"].',
        }),
      ),
      excludeDomains: Type.Optional(Type.Array(Type.String(), { description: "Drop results from these domains." })),
      startPublishedDate: Type.Optional(
        Type.String({ description: "ISO 8601 date; only return pages published after it." }),
      ),
      fresh: Type.Optional(
        Type.Boolean({ description: "Force a live crawl instead of cached content. Slower; use for breaking news." }),
      ),
      fullText: Type.Optional(
        Type.Boolean({ description: "Also return truncated full page text, not just excerpts. Costs many tokens." }),
      ),
    }),

    async execute(_toolCallId, params, signal, onUpdate) {
      const apiKey = resolveApiKey();
      const mode: Mode = params.mode ?? "auto";
      const fullText = params.fullText === true;

      onUpdate?.({
        content: [{ type: "text", text: `Searching (${mode}): ${params.query}` }],
        details: { query: params.query, mode },
      });

      const body: Record<string, unknown> = {
        query: params.query,
        type: MODES[mode],
        numResults: params.numResults ?? DEFAULT_NUM_RESULTS,
        contents: {
          highlights: true,
          ...(fullText ? { text: { maxCharacters: FULL_TEXT_MAX_CHARACTERS } } : {}),
          ...(params.fresh ? { maxAgeHours: 0 } : {}),
        },
      };
      if (mode === "deep") {
        body.systemPrompt = DEEP_SYSTEM_PROMPT;
        body.outputSchema = DEEP_OUTPUT_SCHEMA;
      }
      if (params.includeDomains?.length) body.includeDomains = params.includeDomains;
      if (params.excludeDomains?.length) body.excludeDomains = params.excludeDomains;
      if (params.startPublishedDate) body.startPublishedDate = params.startPublishedDate;

      const controller = new AbortController();
      const abort = () => controller.abort();
      signal?.addEventListener("abort", abort, { once: true });
      const timeout = setTimeout(abort, DEFAULT_TIMEOUT_MS);

      let response: Response;
      let raw: string;
      try {
        response = await fetch(SEARCH_URL, {
          method: "POST",
          headers: {
            authorization: `Bearer ${apiKey}`,
            "content-type": "application/json",
          },
          body: JSON.stringify(body),
          signal: controller.signal,
        });
        raw = await response.text();
      } catch (error) {
        if (signal?.aborted) return { content: [{ type: "text", text: "Cancelled" }], details: {} };
        const reason = error instanceof Error ? error.message : String(error);
        throw new Error(`web_search: request failed: ${reason}`);
      } finally {
        clearTimeout(timeout);
        signal?.removeEventListener("abort", abort);
      }

      let payload: ExaResponse;
      try {
        payload = JSON.parse(raw) as ExaResponse;
      } catch {
        throw new Error(`web_search: Exa returned non-JSON (HTTP ${response.status}): ${truncate(raw, 300)}`);
      }

      if (!response.ok) {
        const detail = payload.error ?? truncate(raw, 300);
        const hint =
          response.status === 401
            ? " Check the web-search entry in ~/.pi/agent/auth.json."
            : response.status === 429
              ? " Rate limited; retry shortly."
              : "";
        throw new Error(`web_search: Exa error (HTTP ${response.status}): ${detail}${hint}`);
      }

      return {
        content: [{ type: "text", text: formatResults(payload, fullText) }],
        details: {
          query: params.query,
          mode,
          requestId: payload.requestId,
          searchType: payload.searchType,
          resultCount: payload.results?.length ?? 0,
          costDollars: payload.costDollars?.total,
          urls: (payload.results ?? []).map((result) => result.url).filter(Boolean),
        },
      };
    },
  });
}
