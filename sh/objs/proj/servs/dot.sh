function dot_() {
    local proj_name="$1"
    local path=$(yq e ".projects.${proj_name}.local.spec.path" "$YML_PROJECTS" | envsubst)
    if [[ -z "$path" || "$path" == "null" ]]; then
        error_ "'.projects.${proj_name}.local.path' is not set in '$YML_PROJECTS'."
        return 1
    fi
    eval "\"$DOT_\" \"$path\""
}

