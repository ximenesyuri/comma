function label_ {
    local proj_="$1"
    local action="$2"

    local repo_=$(yq e ".projects.$proj_.spec.repo" $YML_PROJECTS)
    local prov_=$(yq e ".projects.$proj_.spec.provider" $YML_PROJECTS)

    if [[ -z "$repo_" || "$repo_" == "null" ]]; then
        error_ "Missing field '.projects.$proj_.spec.repo' in '$YML_PROJECTS'."
        return 1
    fi
    if [[ -z "$prov_" || "$prov_" == "null" ]]; then
        error_ "Missing field '.projects.$proj_.spec.provider' in '$YML_PROJECTS'."
        return 1
    fi

    case "$action" in
        new)
            new_label "$repo_" "$prov_"
            ;;
        rm)
            remove_label "$repo_" "$prov_"
            ;;
        edit)
            edit_label "$repo_" "$prov_"
            ;;
        ls)
            list_label "$repo_" "$prov_"
            ;;
        *)
            error_ "Label actions: 'new', 'rm', 'edit', or 'ls'."
            return 1
            ;;
    esac
}

function list_label {
    local repo_="$1"
    local prov_="$2"
    local endpoint_=$(get_api "$prov_" ".labels.list.endpoint") 
    local labels=$(call_api "$prov_" "GET" "${endpoint_//:repo/$repo_}")

    printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "Project:" "$proj_"
    printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "Repo:" "$repo_"
    line_

    if [[ -n "$labels" ]]; then
        echo "$labels" | jq -c '.[]' | while read -r label_json; do
            local label_name=$(echo "$label_json" | jq -r '.name')
            local label_color=$(echo "$label_json" | jq -r '.color')
            local label_description=$(echo "$label_json" | jq -r '.description // "No description."')
            local bg_color=$(bg_ $label_color)

            printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "Label:" "$label_name"
            printf "${PRIMARY}%-*s${RESET} ${bg_color}${WHITE}#%s${RESET}\n" $LABEL_WIDTH "Color:" "${label_color}"
            printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "Desc:" "$(fold_ "$label_description")"
            line_
        done
    else
        echo "No labels found for '$repo_'."
    fi
}

function new_label {
    local repo_="$1"
    local prov_="$2"

    primary_ "Label name:"
    input_ -v label_name
    line_
    primary_ -c "Label color" -n "(name or hex without #):"
    input_ -v color_input
    local label_color
    label_color=$(get_hex_ "$color_input")
    if [[ $? -ne 0 || -z "$label_color" ]]; then
        error_ "Label name and color must be valid."
        return 1
    fi
    line_
    primary_ "Label description:"
    input_ -e md -v label_description
    local endpoint_create=$(get_api "$prov_" ".labels.create.endpoint")
    local data="{\"name\": \"$label_name\", \"color\": \"$label_color\", \"description\": \"$label_description\"}"
    response=$(call_api "$prov_" "POST" "${endpoint_create//:repo/$repo_}" "$data")
    if response_ $response; then
        done_ "The label '$label_name' has been created."
    else
        error_ "Failed to create the label '$label_name'."
        error_ "Response: $response"
    fi
}

function remove_label {
    local repo_="$1"
    local prov_="$2"

    local endpoint_=$(get_api "$prov_" ".labels.list.endpoint")
    local labels=$(call_api "$prov_" "GET" "${endpoint_//:repo/$repo_}")

    if [[ -n "$labels" ]]; then
        primary_ "Labels to remove:"
        local label_names=($(echo "$labels" | jq -r '.[] | .name' | fzf --multi $FZF_GEOMETRY))
        if [[ -n "${label_names[@]}" ]]; then
            for label_name in ${label_names[@]}; do
                local label_name_encoded=$(echo -n "$label_name" | jq -sRr @uri)
                local endpoint_delete=$(get_api "$prov_" "labels.delete.endpoint")
                local url="${endpoint_delete//:repo/$repo_}"
                url="${url//:name/$label_name_encoded}"
                response=$(call_api "$prov_" "DELETE" "$url")
                if response_ $response; then
                    done_ "The label $label_name has been removed."
                else
                    error_ "Failed to remove label $label_name."
                    error_ "Response: $response"
                fi
            done
        else
            error_ "No label selected."
        fi
    else
        error_ "No labels found to delete."
    fi
}

function edit_label {
    local repo_="$1"
    local prov_="$2"

    local endpoint_=$(get_api "$prov_" ".labels.list.endpoint")
    local labels=$(call_api "$prov_" "GET" "${endpoint_//:repo/$repo_}")

    if [[ -n "$labels" ]]; then
        local label_name=$(echo "$labels" | jq -r '.[] | .name' | fzf $FZF_GEOMETRY)
        if [[ -n "$label_name" ]]; then
            info_ "Editing label '$label_name'. Leave fields blank to keep it."
            line_
            local current_label=$(echo "$labels" | jq -r --arg name "$label_name" '.[] | select(.name==$name)')
            local current_color=$(echo "$current_label" | jq -r '.color')
            local current_description=$(echo "$current_label" | jq -r '.description')

            primary_ -c "Current Name:" -n "$label_name"
            primary_ "New Name:"
            input_ -e md -v new_name
            new_name=${new_name:-$label_name}
            line_

            primary_ -c "Current Color:" -n "#$current_color"
            primary_ -c "New color" -n "(name or hex without #):"
            input_ -v color_input
            local new_color
            new_color=$(get_hex_ "$color_input")
            if [[ $? -ne 0 || -z "$new_color" ]]; then
                error_ "Label color is not in the given format."
                return 1
            fi
            line_
            echo -e ${PRIMARY}"Current Description:${RESET} $current_description"
            input_ -e md -v new_description
            new_description=${new_description:-$current_description}

            local label_name_encoded=$(echo -n "$label_name" | jq -sRr @uri)
            local endpoint_update=$(get_api "$prov_" ".labels.create.endpoint")
            local url="${endpoint_update//:repo/$repo_}/$label_name_encoded"
            local data="{\"name\": \"$new_name\", \"color\": \"$new_color\", \"description\": \"$new_description\"}"

            response=$(call_api "$prov_" "PATCH" "$url" "$data")
            if response_ $response; then
                done_ "The label '$label_name' has been updated."
            else
                error_ "Failed to update label '$label_name'."
                error_ "Response: $response"
            fi
        else
            error_ "No selected label."
        fi
    else
        error_ "No labels found to edit."
    fi
}
