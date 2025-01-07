function dot_() {
    local proj_name="$1"
    local path=$(yq e ".local.${proj_name}.spec.path" "$YML_LOCAL" | envsubst)
    if [[ -z "$path" || "$path" == "null" ]]; then
        error_ "'.local.${proj_name}.spec.path' is not set in '$YML_LOCAL'."
        return 1
    fi
    eval "\"$DOT_\" \"$path\""
}

