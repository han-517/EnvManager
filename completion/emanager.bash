_emanager() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Top-level commands
    if [[ ${COMP_CWORD} == 1 ]]; then
        opts="use clear list show add remove config"
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
    fi

    # Second-level completions
    case "${COMP_WORDS[1]}" in
        use|show|remove)
            local presets=$(emanager list 2>/dev/null | grep '^- ' | sed 's/^- //')
            COMPREPLY=( $(compgen -W "${presets}" -- ${cur}) )
            ;;
        config)
            if [[ ${COMP_CWORD} == 2 ]]; then
                opts="set-path get-path"
                COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
            fi
            ;;
        add)
            if [[ ${COMP_CWORD} == 2 ]]; then
                local presets=$(emanager list 2>/dev/null | grep '^- ' | sed 's/^- //')
                COMPREPLY=( $(compgen -W "${presets}" -- ${cur}) )
            fi
            ;;
    esac
}

complete -F _emanager emanager
