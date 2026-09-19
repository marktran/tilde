function pi --wraps pi --description 'pi with claude CLI traffic routed through Cloudflare AI Gateway'
    # Pi-scoped Anthropic routing: CE cross-model peer jobs (claude CLI) spawned
    # inside Pi inherit these and hit the Gateway; terminal `claude` keeps the
    # enterprise seat. Token source of truth: Pi's auth.json.
    set -l tok $CLOUDFLARE_API_KEY
    if test -z "$tok"; and test -r ~/.pi/agent/auth.json
        set tok (jq -r '.["cloudflare-ai-gateway"].key // empty' ~/.pi/agent/auth.json 2>/dev/null)
    end
    set -l anthropic_config_dir
    if test -n "$tok"
        # Pi 0.85.1's Anthropic SDK discovers local OAuth even with gateway auth.
        # Hide the enterprise profile only for Pi and its gateway-routed children.
        set anthropic_config_dir (mktemp -d)
        or return $status
        set -fx ANTHROPIC_CONFIG_DIR "$anthropic_config_dir"
        set -fx ANTHROPIC_BASE_URL "https://gateway.ai.cloudflare.com/v1/472017f2a442123c9f8f9da2bb39e5e8/workos/anthropic"
        set -fx ANTHROPIC_API_KEY "$tok"
        set -fx ANTHROPIC_CUSTOM_HEADERS "cf-aig-authorization: Bearer $tok"
    end
    command pi $argv
    set -l pi_status $status
    if test -n "$anthropic_config_dir"
        command rm -rf -- "$anthropic_config_dir"
    end
    return $pi_status
end
