#compdef maurice

# Maurice Tools Zsh Completion
# Place this in /usr/local/share/zsh/site-functions/ or ~/.zsh/completions/

_maurice() {
    local curcontext="$curcontext" state line
    typeset -A opt_args

    _arguments -C \
        '1: :_maurice_commands' \
        '*:: :->subcommand'

    case "$state" in
        subcommand)
            case "$line[1]" in
                secret)
                    _arguments \
                        '1: :_maurice_secret_actions' \
                        '2: :_maurice_providers'
                    ;;
                transcribe)
                    _files -g '*.{m4a,mp3,wav,mp4,mov,aac,flac,m4p,m4v,webm}'
                    ;;
                *)
                    _files
                    ;;
            esac
            ;;
    esac
}

_maurice_commands() {
    local commands=(
        'setup:Bootstrap installation and dependencies'
        'doctor:Check system health and configuration'
        'update:Update maurice-tools to latest version'
        'secret:Manage API keys in macOS Keychain'
        'transcribe:Transcribe audio file to text'
        'version:Show version information'
        'help:Show help message'
    )
    _describe -t commands 'maurice command' commands
}

_maurice_secret_actions() {
    local actions=(
        'set:Store an API key'
        'get:Retrieve an API key'
    )
    _describe -t actions 'secret action' actions
}

_maurice_providers() {
    local providers=(
        'openai:OpenAI Whisper API'
        'deepgram:Deepgram API'
        'anthropic:Anthropic API'
    )
    _describe -t providers 'API provider' providers
}

_maurice "$@"
