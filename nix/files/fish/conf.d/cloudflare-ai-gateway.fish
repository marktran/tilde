# Cloudflare AI Gateway token for CLI use (including Pi's Claude wrapper).
# Codex's ~/bin launcher selects cloudflare-cli.config.toml and also loads
# this token for non-Fish callers. Desktop's shared config stays on OpenAI.
if status is-login; or not set -q CLOUDFLARE_API_KEY
    if test -r ~/.pi/agent/auth.json
        set -l key (jq -r '.["cloudflare-ai-gateway"].key // empty' ~/.pi/agent/auth.json 2>/dev/null)
        if test -n "$key"
            set -gx CLOUDFLARE_API_KEY $key
        end
    end
end

# The executable wrapper handles interactive and non-interactive Codex.
# Clear the retired profile abbreviation when this file is re-sourced.
if status is-interactive
    abbr --erase codex
end
