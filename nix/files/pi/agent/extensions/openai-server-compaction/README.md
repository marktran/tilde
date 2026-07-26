# OpenAI server compaction for Pi

This global Pi extension adds OpenAI Responses remote compaction to compatible
models, including `cloudflare-ai-gateway/*` GPT models routed through
Cloudflare's native `/openai/responses` endpoint.

It is derived from
[`algal/pi-openai-server-compaction`](https://github.com/algal/pi-openai-server-compaction)
at commit `8a3de2f3b0c178fdd6f73f2f94172dfc3943e466`.

## Local adaptation

Compared with upstream, this copy:

- supports Pi's `cloudflare-ai-gateway` provider and header-only
  `cf-aig-authorization` authentication;
- resolves provider-scoped Cloudflare account and gateway placeholders;
- targets `{cloudflare-openai-base}/responses` rather than appending an extra
  `/v1` path;
- preserves Pi's built-in HTTP/SSE provider transport instead of installing the
  upstream direct-OpenAI WebSocket override;
- replays explicit opaque compaction history after a compaction boundary;
- supports Pi 0.82's provider environment and compaction usage accounting;
- recognizes the `max` reasoning level used by GPT-5.6 models.

Normal pre-compaction turns are unchanged: this adaptation does not enable
`store: true` or `previous_response_id`. On manual or automatic Pi compaction it
runs two requests in parallel:

1. a portable text summary for Pi's session/tree/model-switch semantics;
2. an OpenAI Responses request ending in `{ "type": "compaction_trigger" }`.

The returned encrypted `compaction` item is persisted under
`CompactionEntry.details.remoteCompaction` and replaces summarized plaintext in
later compatible OpenAI Responses requests.

Cloudflare support is deliberately restricted to models whose provider API is
`openai-responses` and whose base URL ends in the dedicated `/openai` route.
The `/grok`, `/custom-fireworks-ai`, `/anthropic`, and `/compat` routes are not
intercepted. In particular, Fireworks models keep their configured
`anthropic-messages` or `openai-completions` transports unchanged.

## Configuration

Global: `~/.pi/agent/openai-server-compaction.json`

Project override: `.pi/openai-server-compaction.json`

```json
{
  "enabled": true,
  "notify": true
}
```

Environment overrides:

- `PI_OPENAI_SERVER_COMPACTION_ENABLED=0|1`
- `PI_OPENAI_SERVER_COMPACTION_NOTIFY=0|1`

## Data handling

Compaction sends the current compatible conversation context through the
configured endpoint. With the Cloudflare provider, the request remains routed
through Cloudflare AI Gateway to OpenAI. Remote compaction requests use
`store: false`, but the opaque encrypted artifact is stored in Pi's local
session JSONL. It is provider-native and not human-readable.

## Tests

From this directory:

```bash
node tests/run.mjs
```

The offline suite type-checks against the installed Pi and tests model/route
selection, including Sol/Terra/Luna acceptance and Grok/Fireworks rejection;
Cloudflare endpoint and header construction; all selectable GPT-5.6 thinking
levels; request and SSE handling; opaque-history persistence; cross-model
isolation; and a mocked fetch flow. It makes no network requests.

The explicit live suite makes paid requests through the configured Cloudflare
AI Gateway:

```bash
PI_OPENAI_SERVER_COMPACTION_LIVE=1 node tests/live.mjs
```

Set `PI_OPENAI_SERVER_COMPACTION_TEST_MODEL` to override its default of
`cloudflare-ai-gateway/gpt-5.6-sol`. The live suite verifies all five selectable
thinking levels, opaque artifact-only recall, Pi RPC compaction, and persisted
session resume. It never logs credentials or encrypted artifact contents.

On 2026-07-26, `cloudflare-ai-gateway/gpt-5.6-sol` passed both suites.

Set `enabled` to `false`, use `PI_OPENAI_SERVER_COMPACTION_ENABLED=0`, or remove
the extension path from Pi settings to roll back.
