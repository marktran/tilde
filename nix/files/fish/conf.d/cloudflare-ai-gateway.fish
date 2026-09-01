# Cloudflare AI Gateway token for the codex CLI's default model_provider
# (see ~/.codex/config.toml). Single source of truth: Pi's auth.json.
if status is-login; or not set -q CLOUDFLARE_API_KEY
    if test -r ~/.pi/agent/auth.json
        set -l key (jq -r '.["cloudflare-ai-gateway"].key // empty' ~/.pi/agent/auth.json 2>/dev/null)
        if test -n "$key"
            set -gx CLOUDFLARE_API_KEY $key
        end
    end
end

# Interactive codex keeps ChatGPT auth, but only where a ChatGPT login exists
# (the laptops). Hosts without ~/.codex/auth.json (e.g. the museum VM) stay on
# the Gateway default provider, which needs no login. Scripts and CE
# shell-outs (non-interactive) always use the Gateway default provider.
if status is-interactive; and test -r ~/.codex/auth.json
    abbr -a codex 'codex --profile chatgpt'
end
