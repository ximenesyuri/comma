function manage_labels {
    local project_name="$1"
    local action="$2"

    local project_config
    project_config=$(g_get_project_info "$project_name")

    if [[ -z $project_config || "$project_config" == "null" ]]; then
        echo "error: Project '$project_name' not found."
        return 1
    fi

    local project_repo=$(yq e '.repo' <<< "$project_config")
    local provider=$(yq e '.provider' <<< "$project_config") 

    case "$action" in
        new)
            primary_ "New label name:"
            input_ -v label_name
            line_
            primary_ -c "New label color" -n "(name or hex without #):"
            input_ -v color_input
            local label_color
            label_color=$(get_hex_ "$color_input")
            if [[ $? -ne 0 || -z "$label_color" ]]; then
                error_ "Label name and color must be valid."
                return 1
            fi
            line_
            primary_ "New label description:"
            input -e md -v label_description 
            local endpoint_create=$(g_get_api_info "$provider" "labels.create.endpoint")
            local data="{\"name\": \"$label_name\", \"color\": \"$label_color\", \"description\": \"$label_description\"}"
            response=$(call_api "$provider" "POST" "${endpoint_create//:repo/$project_repo}" "$data")
            if response_ $response; then 
                done_ "The label '$label_name' has been created."
            else
                error_ "Failed to create the label '$label_name'."
                error_ "Response: $response"
            fi
            ;;
        rm)
            local endpoint_list=$(g_get_api_info "$provider" "labels.list.endpoint")
            local labels=$(call_api "$provider" "GET" "${endpoint_list//:repo/$project_repo}")

            if [[ -n "$labels" ]]; then
                primary_ "Labels to remove:"
                local label_names=($(echo "$labels" | jq -r '.[] | .name' | fzf --multi $FZF_GEOMETRY))
                if [[ -n "${label_names[@]}" ]]; then
                    for label_name in ${label_names[@]}; do
                        local label_name_encoded=$(echo -n "$label_name" | jq -sRr @uri)
                        local endpoint_delete=$(g_get_api_info "$provider" "labels.delete.endpoint")
                        local url="${endpoint_delete//:repo/$project_repo}"
                        url="${url//:name/$label_name_encoded}"
                        response=$(call_api "$provider" "DELETE" "$url")
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
            ;;
        edit)
            local endpoint_list=$(g_get_api_info "$provider" "labels.list.endpoint")
            local labels=$(call_api "$provider" "GET" "${endpoint_list//:repo/$project_repo}")

            if [[ -n "$labels" ]]; then
                local label_name=$(echo "$labels" | jq -r '.[] | .name' | fzf)
                if [[ -n "$label_name" ]]; then
                    info_ "Editing label '$label_name'. Leave fields blank to keep it."
                    local current_label=$(echo "$labels" | jq -r --arg name "$label_name" '.[] | select(.name==$name)')
                    local current_color=$(echo "$current_label" | jq -r '.color')
                    local current_description=$(echo "$current_label" | jq -r '.description')

                    echo -e ${PRIMARY}"Current Name:${RESET} $label_name"
                    primary_ "New Name:"
                    input -e md -v new_name
                    new_name=${new_name:-$label_name}
                    line_

                    echo -e ${PRIMARY}"Current Color:${RESET} #$current_color"
                    primary_ "New Color:"
                    input_ -e md -v new_color
                    new_color=${new_color:-$current_color}
                    line_

                    echo -e ${PRIMARY}"Current Description:${RESET} $current_description"
                    input_ -e md -v new_description
                    new_description=${new_description:-$current_description}

                    local label_name_encoded=$(echo -n "$label_name" | jq -sRr @uri)
                    local endpoint_update=$(g_get_api_info "$provider" "labels.create.endpoint")
                    local url="${endpoint_update//:repo/$project_repo}/$label_name_encoded"
                    local data="{\"name\": \"$new_name\", \"color\": \"$new_color\", \"description\": \"$new_description\"}"
                    
                    response=$(call_api "$provider" "PATCH" "$url" "$data")
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
            ;;
        ls)
            local endpoint_list=$(g_get_api_info "$provider" "labels.list.endpoint")
            local labels=$(call_api "$provider" "GET" "${endpoint_list//:repo/$project_repo}")

            printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "Project:" "$project_name"
            printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "Repo:" "$project_repo"
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
                echo "No labels found for '$project_name'."
            fi
            ;; 
        *)
            echo "Invalid action for labels. Use 'new', 'rm', 'edit', or 'ls'."
            return 1
            ;;
    esac
}

