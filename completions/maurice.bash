# Maurice Tools Bash Completion
# Place this in /etc/bash_completion.d/ or source it in your .bashrc

_maurice() {
    local cur prev opts commands
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Main commands
    commands="setup doctor update secret transcribe version help"

    # Top-level completion
    if [[ ${COMP_CWORD} -eq 1 ]]; then
        COMPREPLY=( $(compgen -W "${commands}" -- "${cur}") )
        return 0
    fi

    # Subcommand completions
    case "${COMP_WORDS[1]}" in
        secret)
            if [[ ${COMP_CWORD} -eq 2 ]]; then
                COMPREPLY=( $(compgen -W "set get" -- "${cur}") )
            elif [[ ${COMP_CWORD} -eq 3 ]]; then
                COMPREPLY=( $(compgen -W "openai deepgram anthropic" -- "${cur}") )
            fi
            ;;
        transcribe)
            # Complete with audio files
            local audio_extensions="@(m4a|mp3|wav|mp4|mov|aac|flac|m4p|m4v|webm)"
            COMPREPLY=( $(compgen -f -X "!*.${audio_extensions}" -- "${cur}") )
            # Also complete directories
            COMPREPLY+=( $(compgen -d -- "${cur}") )
            ;;
        update|doctor|setup|version|help)
            # These commands take no additional arguments
            ;;
    esac

    return 0
}

complete -F _maurice maurice
