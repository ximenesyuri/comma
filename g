#! /bin/bash

function g {
    G_CONF="${BASH_SOURCE%/*}/yml/g.yml"
    G_API="${BASH_SOURCE%/*}/yml/api.yml"

    source ${BASH_SOURCE%/*}/sh/conf.sh
    source ${BASH_SOURCE%/*}/sh/style.sh
    source ${BASH_SOURCE%/*}/sh/log.sh
    source ${BASH_SOURCE%/*}/sh/utils.sh
    source ${BASH_SOURCE%/*}/sh/api.sh
    source ${BASH_SOURCE%/*}/sh/help.sh
    source ${BASH_SOURCE%/*}/sh/prj.sh
    source ${BASH_SOURCE%/*}/sh/issue.sh
    source ${BASH_SOURCE%/*}/sh/label.sh

    deps_ || return 1
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
