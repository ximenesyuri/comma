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

    local blue="\033[34m"
    local magenta="\033[35m"
    local reset="\033[0m"
    local label_width=12

    case "$action" in
        new)
            echo "Enter new label name:"
            read -e -r -p "> " label_name
            echo "Enter label color (hex):"
            read -e -r -p "> " label_color
            echo "Enter label description:"
            read -e -r -p "> " label_description
            if [[ -z "$label_name" || -z "$label_color" ]]; then
                echo "error: Label name and color cannot be empty."
                return 1
            fi
            local endpoint_create=$(g_get_api_info "$provider" "labels.create.endpoint")
            local data="{\"name\": \"$label_name\", \"color\": \"$label_color\", \"description\": \"$label_description\"}"
            call_api "$provider" "POST" "${endpoint_create//:repo/$project_repo}" "$data" > /dev/null 2>&1
            ;;
        rm)
            echo "Fetching labels..."
            local endpoint_list=$(g_get_api_info "$provider" "labels.list.endpoint")
            local labels=$(call_api "$provider" "GET" "${endpoint_list//:repo/$project_repo}")

            if [[ -n "$labels" ]]; then
                local label_name=$(echo "$labels" | jq -r '.[] | .name' | fzf --prompt="Select a label to remove: ")
                if [[ -n "$label_name" ]]; then
                    local label_name_encoded=$(echo -n "$label_name" | jq -sRr @uri)
                    local endpoint_delete=$(g_get_api_info "$provider" "labels.delete.endpoint")
                    local url="${endpoint_delete//:repo/$project_repo}"
                    url="${url//:name/$label_name_encoded}"

                    call_api "$provider" "DELETE" "$url" > /dev/null 2>&1
                else
                    echo "No label selected."
                fi
            else
                echo "No labels found to delete."
            fi
            ;;
        edit)
            echo "Fetching labels..."
            local endpoint_list=$(g_get_api_info "$provider" "labels.list.endpoint")
            local labels=$(call_api "$provider" "GET" "${endpoint_list//:repo/$project_repo}")

            if [[ -n "$labels" ]]; then
                local label_name=$(echo "$labels" | jq -r '.[] | .name' | fzf)
                if [[ -n "$label_name" ]]; then
                    echo "Editing label '$label_name'. Leave fields blank to keep existing values."
                    local current_label=$(echo "$labels" | jq -r --arg name "$label_name" '.[] | select(.name==$name)')
                    local current_color=$(echo "$current_label" | jq -r '.color')
                    local current_description=$(echo "$current_label" | jq -r '.description')

                    echo "Current Name: $label_name"
                    read -e -r -p "New Name (leave blank to keep): " new_name
                    new_name=${new_name:-$label_name}

                    echo "Current Color: #$current_color"
                    read -e -r -p "New Color (leave blank to keep): " new_color
                    new_color=${new_color:-$current_color}

                    echo "Current Description: $current_description"
                    read -e -r -p "New Description (leave blank to keep): " new_description
                    new_description=${new_description:-$current_description}

                    local label_name_encoded=$(echo -n "$label_name" | jq -sRr @uri)
                    local endpoint_update=$(g_get_api_info "$provider" "labels.create.endpoint")
                    local url="${endpoint_update//:repo/$project_repo}/$label_name_encoded"
                    local data="{\"name\": \"$new_name\", \"color\": \"$new_color\", \"description\": \"$new_description\"}"
                    
                    call_api "$provider" "PATCH" "$url" "$data" > /dev/null 2>&1
                else
                    echo "No label selected."
                fi
            else
                echo "No labels found to edit."
            fi
            ;;
        ls)
            local endpoint_list=$(g_get_api_info "$provider" "labels.list.endpoint")
            local labels=$(call_api "$provider" "GET" "${endpoint_list//:repo/$project_repo}")

            printf "${blue}%-*s${reset} %s\n" $label_width "Project:" "$project_name"
            printf "${blue}%-*s${reset} %s\n" $label_width "Repo:" "$project_repo"
            echo -e "${magenta}--------------------------------------${reset}"

            if [[ -n "$labels" ]]; then
                echo "$labels" | jq -c '.[]' | while read -r label_json; do
                    local label_name=$(echo "$label_json" | jq -r '.name')
                    local label_color=$(echo "$label_json" | jq -r '.color')
                    local label_description=$(echo "$label_json" | jq -r '.description // "No description."')
                    
                    local r=$((16#${label_color:0:2}))
                    local g=$((16#${label_color:2:2}))
                    local b=$((16#${label_color:4:2}))
                    local ansi_color="\033[38;2;${r};${g};${b}m"

                    printf "${blue}%-*s${reset} %s\n" $label_width "Label:" "$label_name"
                    printf "${blue}%-*s${reset} %b\n" $label_width "Color:" "${ansi_color}#${label_color}${reset}"
                    printf "${blue}%-*s${reset} %s\n" $label_width "Desc:" "$(echo "$label_description" | fold -s -w 80)"
                    echo -e "${magenta}---------------------------------------${reset}"
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

