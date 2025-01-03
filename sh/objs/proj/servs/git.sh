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
            ;;
        c|commit)
            if [[ -z "$param" ]]; then
                error_ "Commit message required."
                popd > /dev/null
                return 1
            fi
            git commit -m "$param"
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
        l|pull)
            if [[ -z "$param" ]]; then
                error_ "Branch name required."
                popd > /dev/null
                return 1
            fi
            git pull origin "$param"
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

