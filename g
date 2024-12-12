#! /bin/bash

function g {
    G_CONF="${BASH_SOURCE%/*}/yml/g.yml"
    G_API="${BASH_SOURCE%/*}/yml/api.yml"

    source ${BASH_SOURCE%/*}/sh/conf.sh
    source ${BASH_SOURCE%/*}/sh/color.sh
    source ${BASH_SOURCE%/*}/sh/utils.sh
    source ${BASH_SOURCE%/*}/sh/api.sh
    source ${BASH_SOURCE%/*}/sh/help.sh
    source ${BASH_SOURCE%/*}/sh/prj.sh
    source ${BASH_SOURCE%/*}/sh/issue.sh
    source ${BASH_SOURCE%/*}/sh/label.sh

    fzf_geometry="--height=20% --layout=reverse"

    check_dependencies || return 1
    local first_arg="$1"

    if [[ -z "$first_arg" ]]; then
        g_help
        return 0
    fi

    if [[ "$first_arg" == "help" || "$first_arg" == "--help" ]]; then
        g_help
        return 0
    fi

    local project_name
    if [[ "$first_arg" == "new" || "$first_arg" == "rm" || "$first_arg" == "ls" ]]; then
        project_name=""
        is_project_command=true
    else
        project_name="$first_arg"
        is_project_command=false
        shift
    fi

    if $is_project_command; then
        case "$first_arg" in
            new)
                g_new
                ;;
            rm)
                g_rm
                ;;
            ls)
                g_ls
                ;;
            *)
                g_help
                ;;
        esac
        return 0
    fi

    local topic="$1"
    shift
    if [[ -z "$topic" ]]; then
        g_help
        return 0
    fi

    case "$topic" in
        i|issue|issues)
            local action="$1"
            shift
            if [[ -z "$action" ]]; then
                g_help
                return 0
            fi

            manage_issues "$project_name" "$action" "$@"
            ;;
        l|label|labels)
            manage_labels "$project_name" "$@"
            ;;
        # Add other topics here
        *)
            g_help
            ;;
    esac
}

function _g_completions() {
    local cur prev commands projects topics

    # Current word being completed
    cur="${COMP_WORDS[COMP_CWORD]}"
    # Previous word in the command line
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # Available commands
    commands=("help" "new" "rm" "ls")
    # Fetch projects using previously defined function
    projects=($(g_get_projects))
    # Topics defined by the script
    declare -A topic_actions=(
        ["issue"]="new ls edit close reopen"
        ["issues"]="new ls edit close reopen"
        ["i"]="new ls edit close reopen"
        ["label"]="new ls edit rm"
        ["labels"]="new ls edit rm"
        ["pr"]="new ls close reopen merge"
        ["mr"]="new ls close reopen merge"
    )
    topics=(${!topic_actions[@]})

    case "$COMP_CWORD" in
        1)
            # Complete the first argument with commands or projects
            COMPREPLY=( $(compgen -W "${commands[*]} ${projects[*]}" -- "$cur") )
            ;;
        2)
            # Check if the first argument is a recognized project
            if [[ " ${projects[*]} " =~ " ${COMP_WORDS[1]} " ]]; then
                # Complete the second argument with topics
                COMPREPLY=( $(compgen -W "${topics[*]}" -- "$cur") )
            fi
            ;;
        3)
            # Check if the second argument is a recognized topic
            if [[ -n "${topic_actions[${COMP_WORDS[2]}]}" ]]; then
                # Complete the third argument with actions related to the topic
                COMPREPLY=( $(compgen -W "${topic_actions[${COMP_WORDS[2]}]}" -- "$cur") )
            fi
            ;;
    esac
}

# Register _g_completions for function g
complete -F _g_completions g

