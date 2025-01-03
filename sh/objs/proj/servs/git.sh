function git_ {
    local proj="$1"
    local action="$2"
    local param="$3"
    local proj_path
    proj_path=$(yq e ".projects.$proj.local.spec.path" "$YML_PROJECTS" | envsubst)

    if [[ -z "$proj_path" || "$proj_path" == "null" ]]; then
        error_ "Project path not set for '$proj'."
        info_ "Check '.projects.$proj.local.spec.path' in '$YML_PROJECTS'."
        return 1
    fi

    pushd "$proj_path" > /dev/null

    case "$action" in
        a|add)
            git add .
            done_ "Changes added to stage in proj '$proj'"
            ;;
        c|commit)
            shift 2
            message="$@"
            if [[ -z "$message" ]]; then
                error_ "Commit message required."
                popd > /dev/null
                return 1
            fi
            git commit -m "$message"
            ;;
        b|branch)
            if [[ -z "$param" ]]; then
                error_ "Branch name required."
                popd > /dev/null
                return 1
            fi
            git checkout -b "$param" || git checkout "$param"
            ;;
        p|push)
            if [[ -z "$param" ]]; then
                error_ "Branch name required."
                popd > /dev/null
                return 1
            fi
            git push origin "$param"
            ;;
        P|pull)
            if [[ -z "$param" ]]; then
                error_ "Branch name required."
                popd > /dev/null
                return 1
            fi
            git pull origin "$param"
            ;;
        A|amend)
            local commit_id=$(git log --oneline | fzf $FZF_GEOMETRY)
            if [[ -n "$commit_id" ]]; then
                primary_ "New message:"
                read -p "> " new_message
                git commit --amend -m "$new_message" --no-edit
                done_ "The commit has been amended."
            else
                error_ "No commit selected."
            fi
            ;;
        *)
            error_ "Unsupported git action: $action."
            popd > /dev/null
            return 1
            ;;
    esac

    popd > /dev/null
    return 0
}

