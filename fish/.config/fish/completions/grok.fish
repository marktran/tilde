# Print an optspec for argparse to handle cmd's options that are independent of any subcommand.
function __fish_grok_global_optspecs
	string join \n v/version cwd= always-approve allow= deny= p/single= prompt-json= prompt-file= verbatim output-format= m/model= reasoning-effort= rules= system-prompt-override= r/resume= load= c/continue s/session-id= w/worktree= restore-code no-plan no-subagents no-ask-user experimental-memory no-memory agent= agents= tools= disallowed-tools= effort= max-turns= permission-mode= disable-web-search check best-of-n= sandbox= storage-mode= client-identifier= hunk-tracker-mode= terminal fs-read fs-write no-auto-update todo-gate installer= no-alt-screen log-sampling force-login oauth leader no-leader hub-url= hub-workspace-mode= h/help
end

function __fish_grok_needs_command
	# Figure out if the current invocation already has a command.
	set -l cmd (commandline -opc)
	set -e cmd[1]
	argparse -s (__fish_grok_global_optspecs) -- $cmd 2>/dev/null
	or return
	if set -q argv[1]
		# Also print the command, so this can be used to figure out what it is.
		echo $argv[1]
		return 1
	end
	return 0
end

function __fish_grok_using_subcommand
	set -l cmd (__fish_grok_needs_command)
	test -z "$cmd"
	and return 1
	contains -- $cmd[1] $argv
end

complete -c grok -n "__fish_grok_needs_command" -l cwd -d 'Working directory' -r -F
complete -c grok -n "__fish_grok_needs_command" -l allow -d 'Permission allow rule (Claude Code: --allowedTools)' -r
complete -c grok -n "__fish_grok_needs_command" -l deny -d 'Permission deny rule (Claude Code: --disallowedTools)' -r
complete -c grok -n "__fish_grok_needs_command" -s p -l single -d 'Single-turn prompt. Prints the response to stdout and exits' -r
complete -c grok -n "__fish_grok_needs_command" -l prompt-json -d 'Single-turn prompt as JSON content blocks' -r
complete -c grok -n "__fish_grok_needs_command" -l prompt-file -d 'Single-turn prompt from a file' -r -F
complete -c grok -n "__fish_grok_needs_command" -l output-format -d 'Output format for headless mode' -r -f -a "plain\t''
json\t''
streaming-json\t''"
complete -c grok -n "__fish_grok_needs_command" -s m -l model -d 'Model ID to use' -r
complete -c grok -n "__fish_grok_needs_command" -l reasoning-effort -d 'Reasoning effort for reasoning models' -r
complete -c grok -n "__fish_grok_needs_command" -l rules -d 'Extra rules to append to the system prompt' -r
complete -c grok -n "__fish_grok_needs_command" -l system-prompt-override -d 'Override the agent\'s system prompt (Claude Code: --system-prompt)' -r
complete -c grok -n "__fish_grok_needs_command" -s r -l resume -d 'Resume a session by ID, or the most recent if omitted' -r
complete -c grok -n "__fish_grok_needs_command" -l load -d 'Resume a previous session by session ID (alias for --resume)' -r
complete -c grok -n "__fish_grok_needs_command" -s s -l session-id -d 'Create or resume a session with a specific ID (upsert semantics). If the session exists, it is loaded; otherwise a new session is created with the given ID. Hidden from --help' -r
complete -c grok -n "__fish_grok_needs_command" -s w -l worktree -d 'Start the session in a new git worktree, optionally named' -r
complete -c grok -n "__fish_grok_needs_command" -l agent -d 'Agent name or definition file path' -r
complete -c grok -n "__fish_grok_needs_command" -l agents -d 'Inline subagent definitions as JSON' -r
complete -c grok -n "__fish_grok_needs_command" -l tools -d 'Built-in tools to allow (comma-separated)' -r
complete -c grok -n "__fish_grok_needs_command" -l disallowed-tools -d 'Built-in tools to remove (comma-separated)' -r
complete -c grok -n "__fish_grok_needs_command" -l effort -d 'Effort level' -r -f -a "low\t''
medium\t''
high\t''
xhigh\t''
max\t''"
complete -c grok -n "__fish_grok_needs_command" -l max-turns -d 'Maximum number of agent turns' -r
complete -c grok -n "__fish_grok_needs_command" -l permission-mode -d 'Permission mode' -r -f -a "default\t''
acceptEdits\t''
auto\t''
dontAsk\t''
bypassPermissions\t''
plan\t''"
complete -c grok -n "__fish_grok_needs_command" -l best-of-n -d 'Run the task N ways in parallel and pick the best (headless only)' -r
complete -c grok -n "__fish_grok_needs_command" -l sandbox -d 'Sandbox profile for filesystem and network access' -r
complete -c grok -n "__fish_grok_needs_command" -l storage-mode -d 'Session storage mode: local or writeback' -r
complete -c grok -n "__fish_grok_needs_command" -l client-identifier -d 'Override the client identifier sent to the agent' -r
complete -c grok -n "__fish_grok_needs_command" -l hunk-tracker-mode -d 'Hunk tracker mode: agent_only or all_dirty' -r
complete -c grok -n "__fish_grok_needs_command" -l installer -d 'Set the installer field in config.toml' -r
complete -c grok -n "__fish_grok_needs_command" -l hub-url -d 'Computer Hub WebSocket URL for tool sharing' -r
complete -c grok -n "__fish_grok_needs_command" -l hub-workspace-mode -d 'Workspace mode: "local" (default) or "remote=<server-id>"' -r
complete -c grok -n "__fish_grok_needs_command" -s v -l version -d 'Print version'
complete -c grok -n "__fish_grok_needs_command" -l always-approve -d 'Auto-approve all tool executions'
complete -c grok -n "__fish_grok_needs_command" -l verbatim -d 'Send the prompt exactly as given'
complete -c grok -n "__fish_grok_needs_command" -s c -l continue -d 'Continue the most recent session for the current working directory'
complete -c grok -n "__fish_grok_needs_command" -l restore-code -d 'Check out the original session\'s commit when resuming'
complete -c grok -n "__fish_grok_needs_command" -l no-plan -d 'Disable plan mode'
complete -c grok -n "__fish_grok_needs_command" -l no-subagents -d 'Disable subagent spawning'
complete -c grok -n "__fish_grok_needs_command" -l no-ask-user -d 'Disable structured question prompts from the agent'
complete -c grok -n "__fish_grok_needs_command" -l experimental-memory -d 'Enable cross-session memory'
complete -c grok -n "__fish_grok_needs_command" -l no-memory -d 'Disable cross-session memory for this session'
complete -c grok -n "__fish_grok_needs_command" -l disable-web-search -d 'Disable web search and web fetch tools'
complete -c grok -n "__fish_grok_needs_command" -l check -d 'Append a self-verification loop to the prompt (headless only)'
complete -c grok -n "__fish_grok_needs_command" -l terminal -d 'Enable terminal support for the agent'
complete -c grok -n "__fish_grok_needs_command" -l fs-read -d 'Enable client-side file reads'
complete -c grok -n "__fish_grok_needs_command" -l fs-write -d 'Enable client-side file writes'
complete -c grok -n "__fish_grok_needs_command" -l no-auto-update -d 'Disable automatic updates'
complete -c grok -n "__fish_grok_needs_command" -l todo-gate -d 'Enable the runtime turn-end TodoGate for this session'
complete -c grok -n "__fish_grok_needs_command" -l no-alt-screen -d 'Run inline instead of using the terminal alternate screen'
complete -c grok -n "__fish_grok_needs_command" -l log-sampling -d 'Write sampling events to ~/.grok/logs/sampling.jsonl'
complete -c grok -n "__fish_grok_needs_command" -l force-login -d 'Show the login screen even when credentials are already available'
complete -c grok -n "__fish_grok_needs_command" -l oauth -d 'Use OAuth when the welcome screen starts authentication'
complete -c grok -n "__fish_grok_needs_command" -l leader -d 'Connect to a shared leader process'
complete -c grok -n "__fish_grok_needs_command" -l no-leader -d 'Run standalone even when leader mode is configured'
complete -c grok -n "__fish_grok_needs_command" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c grok -n "__fish_grok_needs_command" -f -a "agent" -d 'Run Grok without the interactive UI'
complete -c grok -n "__fish_grok_needs_command" -f -a "import" -d 'Import sessions into Grok'
complete -c grok -n "__fish_grok_needs_command" -f -a "inspect" -d 'Show the configuration Grok discovers for this directory'
complete -c grok -n "__fish_grok_needs_command" -f -a "leader" -d 'Manage running leader processes'
complete -c grok -n "__fish_grok_needs_command" -f -a "logout" -d 'Sign out and clear cached credentials'
complete -c grok -n "__fish_grok_needs_command" -f -a "login" -d 'Sign in to Grok'
complete -c grok -n "__fish_grok_needs_command" -f -a "mcp" -d 'Manage MCP server configurations'
complete -c grok -n "__fish_grok_needs_command" -f -a "plugin" -d 'Manage plugins and marketplace sources'
complete -c grok -n "__fish_grok_needs_command" -f -a "memory" -d 'Manage cross-session memory'
complete -c grok -n "__fish_grok_needs_command" -f -a "models" -d 'List available models and exit'
complete -c grok -n "__fish_grok_needs_command" -f -a "sessions" -d 'List, search, or restore sessions'
complete -c grok -n "__fish_grok_needs_command" -f -a "setup" -d 'Fetch and install managed deployment configuration'
complete -c grok -n "__fish_grok_needs_command" -f -a "share" -d 'Share a session and print the share URL (internal only)'
complete -c grok -n "__fish_grok_needs_command" -f -a "ssh" -d 'Run ssh with local clipboard support'
complete -c grok -n "__fish_grok_needs_command" -f -a "export" -d 'Export a session transcript as Markdown'
complete -c grok -n "__fish_grok_needs_command" -f -a "trace" -d 'Export or upload session trace data'
complete -c grok -n "__fish_grok_needs_command" -f -a "update" -d 'Check for updates or install a specific version'
complete -c grok -n "__fish_grok_needs_command" -f -a "version" -d 'Print version information'
complete -c grok -n "__fish_grok_needs_command" -f -a "v" -d 'Print version information'
complete -c grok -n "__fish_grok_needs_command" -f -a "completions" -d 'Generate shell completion scripts (bash, zsh, fish, powershell, ...)'
complete -c grok -n "__fish_grok_needs_command" -f -a "worktree" -d 'Manage git worktrees'
complete -c grok -n "__fish_grok_needs_command" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -s m -l model -d 'Model ID to use' -r
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -l reasoning-effort -d 'Reasoning effort for reasoning models' -r
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -l agent-profile -d 'Path to an agent profile file' -r -F
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -l grok-ws-origin -r
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -l grok-ws-url -r
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -l cli-chat-proxy-base-url -d 'Override the CLI chat proxy base URL' -r
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -l xai-api-base-url -d 'Override the public xAI API base URL' -r
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -l reauth -l --reauthenticate -d 'Run authentication before starting the agent'
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -l always-approve -d 'Auto-approve all tool executions'
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -l leader -d 'Connect to a shared leader process instead of starting a new agent. Allows multiple clients to share one backend. Defaults to [cli] use_leader in config.toml'
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -l no-leader -d 'Start a new agent even when config enables leader mode'
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -f -a "stdio" -d 'Run the agent over stdio'
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -f -a "headless" -d 'Run the agent headlessly over the Grok WebSocket relay'
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -f -a "serve" -d 'Run the agent as a WebSocket server'
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -f -a "leader" -d 'Run as the shared leader process for other clients'
complete -c grok -n "__fish_grok_using_subcommand agent; and not __fish_seen_subcommand_from stdio headless serve leader help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from stdio" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from headless" -l grok-ws-origin -r
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from headless" -l grok-ws-url -r
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from headless" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from serve" -l bind -d 'Address for the server to listen on' -r
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from serve" -l secret -d 'Secret token for client authentication (auto-generated if not provided)' -r
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from serve" -l remote -d 'Remote agent URL for proxy mode' -r
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from serve" -l grok-ws-origin -r
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from serve" -l grok-ws-url -r
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from serve" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from leader" -l grok-ws-origin -r
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from leader" -l grok-ws-url -r
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from leader" -l no-exit-on-disconnect -d 'Keep the leader running after the last client disconnects'
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from leader" -l no-auto-update -d 'Disable periodic auto-update checks for the leader'
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from leader" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from help" -f -a "stdio" -d 'Run the agent over stdio'
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from help" -f -a "headless" -d 'Run the agent headlessly over the Grok WebSocket relay'
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from help" -f -a "serve" -d 'Run the agent as a WebSocket server'
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from help" -f -a "leader" -d 'Run as the shared leader process for other clients'
complete -c grok -n "__fish_grok_using_subcommand agent; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand import" -l list -d 'List available sessions without importing'
complete -c grok -n "__fish_grok_using_subcommand import" -l json -d 'NDJSON output to stdout'
complete -c grok -n "__fish_grok_using_subcommand import" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand inspect" -l json -d 'Emit machine-readable JSON output'
complete -c grok -n "__fish_grok_using_subcommand inspect" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand leader; and not __fish_seen_subcommand_from list info kill profile help" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand leader; and not __fish_seen_subcommand_from list info kill profile help" -f -a "list" -d 'List running leader processes'
complete -c grok -n "__fish_grok_using_subcommand leader; and not __fish_seen_subcommand_from list info kill profile help" -f -a "info" -d 'Show details for a leader process'
complete -c grok -n "__fish_grok_using_subcommand leader; and not __fish_seen_subcommand_from list info kill profile help" -f -a "kill" -d 'Stop all running leader processes'
complete -c grok -n "__fish_grok_using_subcommand leader; and not __fish_seen_subcommand_from list info kill profile help" -f -a "profile" -d 'Manage CPU profiling for a leader process'
complete -c grok -n "__fish_grok_using_subcommand leader; and not __fish_seen_subcommand_from list info kill profile help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from list" -l json -d 'Emit machine-readable JSON output'
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from info" -l pid -d 'Leader process ID from `grok leader list`' -r
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from info" -l json -d 'Emit machine-readable JSON output'
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from info" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from kill" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from profile" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from profile" -f -a "status" -d 'Show profiling status'
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from profile" -f -a "start" -d 'Start CPU profiling'
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from profile" -f -a "stop" -d 'Stop CPU profiling'
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from profile" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from help" -f -a "list" -d 'List running leader processes'
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from help" -f -a "info" -d 'Show details for a leader process'
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from help" -f -a "kill" -d 'Stop all running leader processes'
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from help" -f -a "profile" -d 'Manage CPU profiling for a leader process'
complete -c grok -n "__fish_grok_using_subcommand leader; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand logout" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand login" -l legacy -d 'Ignored (kept for backwards compatibility). OAuth2 is now the only auth method'
complete -c grok -n "__fish_grok_using_subcommand login" -l oauth -d 'Use Grok OAuth via auth.x.ai'
complete -c grok -n "__fish_grok_using_subcommand login" -l device-auth -d 'Use device-code authentication for headless environments'
complete -c grok -n "__fish_grok_using_subcommand login" -l devbox -d 'Mint credentials via explorer-service (devbox pods only)'
complete -c grok -n "__fish_grok_using_subcommand login" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand mcp; and not __fish_seen_subcommand_from list add remove doctor help" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand mcp; and not __fish_seen_subcommand_from list add remove doctor help" -f -a "list" -d 'List configured MCP servers'
complete -c grok -n "__fish_grok_using_subcommand mcp; and not __fish_seen_subcommand_from list add remove doctor help" -f -a "add" -d 'Add or update an MCP server configuration'
complete -c grok -n "__fish_grok_using_subcommand mcp; and not __fish_seen_subcommand_from list add remove doctor help" -f -a "remove" -d 'Remove an MCP server configuration'
complete -c grok -n "__fish_grok_using_subcommand mcp; and not __fish_seen_subcommand_from list add remove doctor help" -f -a "doctor" -d 'Diagnose MCP server configuration and connectivity'
complete -c grok -n "__fish_grok_using_subcommand mcp; and not __fish_seen_subcommand_from list add remove doctor help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from list" -l json -d 'Emit machine-readable JSON output'
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from add" -l command -d 'Command to run for stdio transport' -r
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from add" -l args -d 'Arguments to pass to the command' -r
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from add" -l env -d 'Environment variables (KEY=VALUE)' -r
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from add" -l url -d 'Server URL for HTTP or SSE transport' -r
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from add" -l type -d 'Transport type for HTTP servers' -r
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from add" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from remove" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from doctor" -l json -d 'Emit machine-readable JSON output'
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from doctor" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from help" -f -a "list" -d 'List configured MCP servers'
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from help" -f -a "add" -d 'Add or update an MCP server configuration'
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from help" -f -a "remove" -d 'Remove an MCP server configuration'
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from help" -f -a "doctor" -d 'Diagnose MCP server configuration and connectivity'
complete -c grok -n "__fish_grok_using_subcommand mcp; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand plugin; and not __fish_seen_subcommand_from list install uninstall rm remove update enable disable details validate tag marketplace help" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand plugin; and not __fish_seen_subcommand_from list install uninstall rm remove update enable disable details validate tag marketplace help" -f -a "list" -d 'List installed plugins'
complete -c grok -n "__fish_grok_using_subcommand plugin; and not __fish_seen_subcommand_from list install uninstall rm remove update enable disable details validate tag marketplace help" -f -a "install" -d 'Install a plugin from a git URL or local path'
complete -c grok -n "__fish_grok_using_subcommand plugin; and not __fish_seen_subcommand_from list install uninstall rm remove update enable disable details validate tag marketplace help" -f -a "uninstall" -d 'Uninstall an installed plugin by name'
complete -c grok -n "__fish_grok_using_subcommand plugin; and not __fish_seen_subcommand_from list install uninstall rm remove update enable disable details validate tag marketplace help" -f -a "rm" -d 'Uninstall an installed plugin by name'
complete -c grok -n "__fish_grok_using_subcommand plugin; and not __fish_seen_subcommand_from list install uninstall rm remove update enable disable details validate tag marketplace help" -f -a "remove" -d 'Uninstall an installed plugin by name'
complete -c grok -n "__fish_grok_using_subcommand plugin; and not __fish_seen_subcommand_from list install uninstall rm remove update enable disable details validate tag marketplace help" -f -a "update" -d 'Update installed plugin(s)'
complete -c grok -n "__fish_grok_using_subcommand plugin; and not __fish_seen_subcommand_from list install uninstall rm remove update enable disable details validate tag marketplace help" -f -a "enable" -d 'Enable a disabled plugin'
complete -c grok -n "__fish_grok_using_subcommand plugin; and not __fish_seen_subcommand_from list install uninstall rm remove update enable disable details validate tag marketplace help" -f -a "disable" -d 'Disable a plugin without uninstalling it'
complete -c grok -n "__fish_grok_using_subcommand plugin; and not __fish_seen_subcommand_from list install uninstall rm remove update enable disable details validate tag marketplace help" -f -a "details" -d 'Show a plugin\'s component inventory'
complete -c grok -n "__fish_grok_using_subcommand plugin; and not __fish_seen_subcommand_from list install uninstall rm remove update enable disable details validate tag marketplace help" -f -a "validate" -d 'Validate a plugin manifest'
complete -c grok -n "__fish_grok_using_subcommand plugin; and not __fish_seen_subcommand_from list install uninstall rm remove update enable disable details validate tag marketplace help" -f -a "tag" -d 'Create a release git tag from the plugin\'s manifest version'
complete -c grok -n "__fish_grok_using_subcommand plugin; and not __fish_seen_subcommand_from list install uninstall rm remove update enable disable details validate tag marketplace help" -f -a "marketplace" -d 'Manage marketplace sources'
complete -c grok -n "__fish_grok_using_subcommand plugin; and not __fish_seen_subcommand_from list install uninstall rm remove update enable disable details validate tag marketplace help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from list" -l json -d 'Emit machine-readable JSON output'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from list" -l available -d 'Include available plugins from marketplace sources. Requires --json'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from install" -l trust -d 'Trust the plugin immediately (skip confirmation prompt)'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from install" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from uninstall" -l confirm -d 'Skip confirmation for multi-plugin repos'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from uninstall" -l keep-data -d 'Preserve the plugin\'s persistent data directory'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from uninstall" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from rm" -l confirm -d 'Skip confirmation for multi-plugin repos'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from rm" -l keep-data -d 'Preserve the plugin\'s persistent data directory'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from rm" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from remove" -l confirm -d 'Skip confirmation for multi-plugin repos'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from remove" -l keep-data -d 'Preserve the plugin\'s persistent data directory'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from remove" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from update" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from enable" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from disable" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from details" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from validate" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from tag" -l push -d 'Push the tag to the remote after creating it'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from tag" -s f -l force -d 'Create the tag even if the working tree is dirty or tag exists'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from tag" -l dry-run -d 'Print what would be tagged without creating the tag'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from tag" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from marketplace" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from marketplace" -f -a "list" -d 'List configured marketplace sources and their plugins'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from marketplace" -f -a "add" -d 'Add a marketplace source (git URL or GitHub shorthand)'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from marketplace" -f -a "remove" -d 'Remove a marketplace source and uninstall its plugins'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from marketplace" -f -a "update" -d 'Refresh marketplace source(s) and sync git caches'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from marketplace" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from help" -f -a "list" -d 'List installed plugins'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from help" -f -a "install" -d 'Install a plugin from a git URL or local path'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from help" -f -a "uninstall" -d 'Uninstall an installed plugin by name'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from help" -f -a "update" -d 'Update installed plugin(s)'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from help" -f -a "enable" -d 'Enable a disabled plugin'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from help" -f -a "disable" -d 'Disable a plugin without uninstalling it'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from help" -f -a "details" -d 'Show a plugin\'s component inventory'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from help" -f -a "validate" -d 'Validate a plugin manifest'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from help" -f -a "tag" -d 'Create a release git tag from the plugin\'s manifest version'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from help" -f -a "marketplace" -d 'Manage marketplace sources'
complete -c grok -n "__fish_grok_using_subcommand plugin; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand memory; and not __fish_seen_subcommand_from clear help" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand memory; and not __fish_seen_subcommand_from clear help" -f -a "clear" -d 'Clear memory files (workspace by default)'
complete -c grok -n "__fish_grok_using_subcommand memory; and not __fish_seen_subcommand_from clear help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand memory; and __fish_seen_subcommand_from clear" -l workspace -d 'Clear workspace-scoped memory (MEMORY.md, sessions/, index.sqlite)'
complete -c grok -n "__fish_grok_using_subcommand memory; and __fish_seen_subcommand_from clear" -l global -d 'Clear global MEMORY.md'
complete -c grok -n "__fish_grok_using_subcommand memory; and __fish_seen_subcommand_from clear" -l all -d 'Clear both workspace and global memory'
complete -c grok -n "__fish_grok_using_subcommand memory; and __fish_seen_subcommand_from clear" -s y -l yes -d 'Skip confirmation prompt'
complete -c grok -n "__fish_grok_using_subcommand memory; and __fish_seen_subcommand_from clear" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand memory; and __fish_seen_subcommand_from help" -f -a "clear" -d 'Clear memory files (workspace by default)'
complete -c grok -n "__fish_grok_using_subcommand memory; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand models" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand sessions; and not __fish_seen_subcommand_from list search help" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand sessions; and not __fish_seen_subcommand_from list search help" -f -a "list" -d 'List recent sessions (same as search with no query)'
complete -c grok -n "__fish_grok_using_subcommand sessions; and not __fish_seen_subcommand_from list search help" -f -a "search" -d 'Search sessions by keyword'
complete -c grok -n "__fish_grok_using_subcommand sessions; and not __fish_seen_subcommand_from list search help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand sessions; and __fish_seen_subcommand_from list" -s n -l limit -d 'Maximum number of sessions to show' -r
complete -c grok -n "__fish_grok_using_subcommand sessions; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand sessions; and __fish_seen_subcommand_from search" -s n -l limit -d 'Maximum number of sessions to show' -r
complete -c grok -n "__fish_grok_using_subcommand sessions; and __fish_seen_subcommand_from search" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand sessions; and __fish_seen_subcommand_from help" -f -a "list" -d 'List recent sessions (same as search with no query)'
complete -c grok -n "__fish_grok_using_subcommand sessions; and __fish_seen_subcommand_from help" -f -a "search" -d 'Search sessions by keyword'
complete -c grok -n "__fish_grok_using_subcommand sessions; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand setup" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand share" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand ssh" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c grok -n "__fish_grok_using_subcommand export" -s c -l clipboard -d 'Copy to clipboard instead of writing to stdout'
complete -c grok -n "__fish_grok_using_subcommand export" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand trace" -s o -l output -d 'Output path (default: ~/.grok/trace-exports/<session-id>.tar.gz)' -r -F
complete -c grok -n "__fish_grok_using_subcommand trace" -l local -d 'Save locally only, skip remote upload'
complete -c grok -n "__fish_grok_using_subcommand trace" -l json -d 'Emit machine-readable JSON output'
complete -c grok -n "__fish_grok_using_subcommand trace" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand update" -l version -d 'Install a specific version (e.g. 0.1.150 or 0.1.151-alpha.2)' -r
complete -c grok -n "__fish_grok_using_subcommand update" -l check -d 'Check for updates without installing'
complete -c grok -n "__fish_grok_using_subcommand update" -l json -d 'Emit machine-readable JSON output (for --check)'
complete -c grok -n "__fish_grok_using_subcommand update" -l force-reinstall -d 'Force re-download and install even if already up to date'
complete -c grok -n "__fish_grok_using_subcommand update" -l alpha -d 'Switch to the alpha release channel (faster updates, may have bugs)'
complete -c grok -n "__fish_grok_using_subcommand update" -l stable -d 'Switch to the stable release channel (default, weekly releases)'
complete -c grok -n "__fish_grok_using_subcommand update" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand version" -l json -d 'Emit machine-readable JSON output'
complete -c grok -n "__fish_grok_using_subcommand version" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand v" -l json -d 'Emit machine-readable JSON output'
complete -c grok -n "__fish_grok_using_subcommand v" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand completions" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand worktree; and not __fish_seen_subcommand_from list show rm gc db help" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand worktree; and not __fish_seen_subcommand_from list show rm gc db help" -f -a "list" -d 'List tracked worktrees'
complete -c grok -n "__fish_grok_using_subcommand worktree; and not __fish_seen_subcommand_from list show rm gc db help" -f -a "show" -d 'Show details for a specific worktree'
complete -c grok -n "__fish_grok_using_subcommand worktree; and not __fish_seen_subcommand_from list show rm gc db help" -f -a "rm" -d 'Remove worktrees'
complete -c grok -n "__fish_grok_using_subcommand worktree; and not __fish_seen_subcommand_from list show rm gc db help" -f -a "gc" -d 'Garbage-collect orphaned/stale worktrees'
complete -c grok -n "__fish_grok_using_subcommand worktree; and not __fish_seen_subcommand_from list show rm gc db help" -f -a "db" -d 'Database maintenance'
complete -c grok -n "__fish_grok_using_subcommand worktree; and not __fish_seen_subcommand_from list show rm gc db help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from list" -l repo -r
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from list" -l type -r
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from list" -l json
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from list" -l all
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from show" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from rm" -s f -l force
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from rm" -l dry-run
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from rm" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from gc" -l max-age -r
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from gc" -l dry-run
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from gc" -s f -l force
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from gc" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from db" -s h -l help -d 'Print help'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from db" -f -a "rebuild" -d 'Rebuild DB from filesystem scan'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from db" -f -a "stats" -d 'Show DB statistics'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from db" -f -a "path" -d 'Print DB file path'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from db" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from help" -f -a "list" -d 'List tracked worktrees'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from help" -f -a "show" -d 'Show details for a specific worktree'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from help" -f -a "rm" -d 'Remove worktrees'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from help" -f -a "gc" -d 'Garbage-collect orphaned/stale worktrees'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from help" -f -a "db" -d 'Database maintenance'
complete -c grok -n "__fish_grok_using_subcommand worktree; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent import inspect leader logout login mcp plugin memory models sessions setup share ssh export trace update version completions worktree help" -f -a "agent" -d 'Run Grok without the interactive UI'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent import inspect leader logout login mcp plugin memory models sessions setup share ssh export trace update version completions worktree help" -f -a "import" -d 'Import sessions into Grok'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent import inspect leader logout login mcp plugin memory models sessions setup share ssh export trace update version completions worktree help" -f -a "inspect" -d 'Show the configuration Grok discovers for this directory'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent import inspect leader logout login mcp plugin memory models sessions setup share ssh export trace update version completions worktree help" -f -a "leader" -d 'Manage running leader processes'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent import inspect leader logout login mcp plugin memory models sessions setup share ssh export trace update version completions worktree help" -f -a "logout" -d 'Sign out and clear cached credentials'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent import inspect leader logout login mcp plugin memory models sessions setup share ssh export trace update version completions worktree help" -f -a "login" -d 'Sign in to Grok'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent import inspect leader logout login mcp plugin memory models sessions setup share ssh export trace update version completions worktree help" -f -a "mcp" -d 'Manage MCP server configurations'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent import inspect leader logout login mcp plugin memory models sessions setup share ssh export trace update version completions worktree help" -f -a "plugin" -d 'Manage plugins and marketplace sources'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent import inspect leader logout login mcp plugin memory models sessions setup share ssh export trace update version completions worktree help" -f -a "memory" -d 'Manage cross-session memory'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent import inspect leader logout login mcp plugin memory models sessions setup share ssh export trace update version completions worktree help" -f -a "models" -d 'List available models and exit'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent import inspect leader logout login mcp plugin memory models sessions setup share ssh export trace update version completions worktree help" -f -a "sessions" -d 'List, search, or restore sessions'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent import inspect leader logout login mcp plugin memory models sessions setup share ssh export trace update version completions worktree help" -f -a "setup" -d 'Fetch and install managed deployment configuration'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent import inspect leader logout login mcp plugin memory models sessions setup share ssh export trace update version completions worktree help" -f -a "share" -d 'Share a session and print the share URL (internal only)'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent import inspect leader logout login mcp plugin memory models sessions setup share ssh export trace update version completions worktree help" -f -a "ssh" -d 'Run ssh with local clipboard support'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent import inspect leader logout login mcp plugin memory models sessions setup share ssh export trace update version completions worktree help" -f -a "export" -d 'Export a session transcript as Markdown'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent import inspect leader logout login mcp plugin memory models sessions setup share ssh export trace update version completions worktree help" -f -a "trace" -d 'Export or upload session trace data'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent import inspect leader logout login mcp plugin memory models sessions setup share ssh export trace update version completions worktree help" -f -a "update" -d 'Check for updates or install a specific version'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent import inspect leader logout login mcp plugin memory models sessions setup share ssh export trace update version completions worktree help" -f -a "version" -d 'Print version information'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent import inspect leader logout login mcp plugin memory models sessions setup share ssh export trace update version completions worktree help" -f -a "completions" -d 'Generate shell completion scripts (bash, zsh, fish, powershell, ...)'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent import inspect leader logout login mcp plugin memory models sessions setup share ssh export trace update version completions worktree help" -f -a "worktree" -d 'Manage git worktrees'
complete -c grok -n "__fish_grok_using_subcommand help; and not __fish_seen_subcommand_from agent import inspect leader logout login mcp plugin memory models sessions setup share ssh export trace update version completions worktree help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from agent" -f -a "stdio" -d 'Run the agent over stdio'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from agent" -f -a "headless" -d 'Run the agent headlessly over the Grok WebSocket relay'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from agent" -f -a "serve" -d 'Run the agent as a WebSocket server'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from agent" -f -a "leader" -d 'Run as the shared leader process for other clients'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from leader" -f -a "list" -d 'List running leader processes'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from leader" -f -a "info" -d 'Show details for a leader process'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from leader" -f -a "kill" -d 'Stop all running leader processes'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from leader" -f -a "profile" -d 'Manage CPU profiling for a leader process'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from mcp" -f -a "list" -d 'List configured MCP servers'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from mcp" -f -a "add" -d 'Add or update an MCP server configuration'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from mcp" -f -a "remove" -d 'Remove an MCP server configuration'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from mcp" -f -a "doctor" -d 'Diagnose MCP server configuration and connectivity'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from plugin" -f -a "list" -d 'List installed plugins'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from plugin" -f -a "install" -d 'Install a plugin from a git URL or local path'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from plugin" -f -a "uninstall" -d 'Uninstall an installed plugin by name'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from plugin" -f -a "update" -d 'Update installed plugin(s)'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from plugin" -f -a "enable" -d 'Enable a disabled plugin'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from plugin" -f -a "disable" -d 'Disable a plugin without uninstalling it'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from plugin" -f -a "details" -d 'Show a plugin\'s component inventory'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from plugin" -f -a "validate" -d 'Validate a plugin manifest'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from plugin" -f -a "tag" -d 'Create a release git tag from the plugin\'s manifest version'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from plugin" -f -a "marketplace" -d 'Manage marketplace sources'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from memory" -f -a "clear" -d 'Clear memory files (workspace by default)'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from sessions" -f -a "list" -d 'List recent sessions (same as search with no query)'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from sessions" -f -a "search" -d 'Search sessions by keyword'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from worktree" -f -a "list" -d 'List tracked worktrees'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from worktree" -f -a "show" -d 'Show details for a specific worktree'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from worktree" -f -a "rm" -d 'Remove worktrees'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from worktree" -f -a "gc" -d 'Garbage-collect orphaned/stale worktrees'
complete -c grok -n "__fish_grok_using_subcommand help; and __fish_seen_subcommand_from worktree" -f -a "db" -d 'Database maintenance'
