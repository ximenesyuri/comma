#! /bin/bash

function g {
    source ${BASH_SOURCE%/*}/sh/style.sh
    source ${BASH_SOURCE%/*}/sh/log.sh
    source ${BASH_SOURCE%/*}/sh/utils.sh
    source ${BASH_SOURCE%/*}/sh/help.sh

    source ${BASH_SOURCE%/*}/sh/api.sh
    source ${BASH_SOURCE%/*}/sh/conf.sh
    source ${BASH_SOURCE%/*}/sh/prj.sh

    deps_ || return 1
    local first_arg="$1"

    if [[ -z "$first_arg" ]]; then
        help_
        return 0
    fi

    if [[ "$first_arg" == "help" || "$first_arg" == "--help" ]]; then
        help_
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
                new_proj
                ;;
            rm)
                remove_proj
                ;;
            ls)
                list_projs
                ;;
            *)
                help_
                ;;
        esac
        return 0
    fi

    local topic="$1"
    shift
    if [[ -z "$topic" ]]; then
        help_
        return 0
    fi

    case "$topic" in
        i|issue|issues)
            source ${BASH_SOURCE%/*}/sh/issue.sh
            local action="$1"
            shift
            if [[ -z "$action" ]]; then
                help_
                return 0
            fi

            issues_ "$project_name" "$action" "$@"
            ;;
        l|label|labels)
            source ${BASH_SOURCE%/*}/sh/label.sh
            labels_ "$project_name" "$@"
            ;;
        # Add other topics here
        *)
            help_
            ;;
    esac
}
