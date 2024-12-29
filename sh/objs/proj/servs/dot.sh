function dot_() {
    local proj_name="$1"
    local path=$(yq e ".projects.${proj_name}.local.spec.path" "$YML_PROJECTS" | envsubst)
    if [[ -z "$path" || "$path" == "null" ]]; then
        error_ "'.projects.${proj_name}.local.path' is not set in '$YML_PROJECTS'."
        return 1
    fi
    local local_dot=$(yq e ".projects.${proj_name}.spec.dot" "$YML_PROJECTS")
    local global_dot=$(yq  e ".globals.dot" "$YML_GLOBALS")
    local DOT_=${G_DOT:-cd}
    if [[ -z "$local_dot" || "$local_dot" == "null" ]]; then
        if [[ -z "$global_dot" || "$global_dot" == "null" ]]; then
            "${DOT_}" "$path"
        else
            "$local_dot" "$path"
        fi
    else
        "$global_dot" "$path"
    fi 
}

