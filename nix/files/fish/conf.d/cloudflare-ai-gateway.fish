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

# Interactive codex keeps ChatGPT auth; scripts and CE shell-outs (non-interactive)
# use the Gateway default provider. Abbreviations only expand interactively.
if status is-interactive
    abbr -a codex 'codex --profile chatgpt'
end
