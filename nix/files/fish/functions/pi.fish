function pi --wraps pi --description 'pi with claude CLI traffic routed through Cloudflare AI Gateway'
    # Pi-scoped Anthropic routing: CE cross-model peer jobs (claude CLI) spawned
    # inside Pi inherit these and hit the Gateway; terminal `claude` keeps the
    # enterprise seat. Token source of truth: Pi's auth.json.
    set -l tok $CLOUDFLARE_API_KEY
    if test -z "$tok"; and test -r ~/.pi/agent/auth.json
        set tok (jq -r '.["cloudflare-ai-gateway"].key // empty' ~/.pi/agent/auth.json 2>/dev/null)
    end
    if test -n "$tok"
        set -fx ANTHROPIC_BASE_URL "https://gateway.ai.cloudflare.com/v1/472017f2a442123c9f8f9da2bb39e5e8/workos/anthropic"
        set -fx ANTHROPIC_API_KEY "$tok"
        set -fx ANTHROPIC_CUSTOM_HEADERS "cf-aig-authorization: Bearer $tok"
    end
    command pi $argv
end
