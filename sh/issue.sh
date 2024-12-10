function manage_issues {
    local project_name="$1"
    local action="$2"
    shift 2

    local project_config
    project_config=$(g_get_project_info "$project_name")

    if [[ -z "$project_config" || "$project_config" == "null" ]]; then
        echo "error: Project '$project_name' not found."
        return 1
    fi

    if [[ $(yq e '.issues' <<< "$project_config") != "true" ]]; then
        echo "error: Project '$project_name' does not support issues."
        return 2
    fi

    local project_repo=$(yq e '.repo' <<< "$project_config")
    local provider=$(yq e '.provider' <<< "$project_config")

    case "$action" in
        new|n)
            create_new_issue "$project_repo" "$provider"
            ;;
        ls)
            list_issues "$project_repo" "$provider"
            ;;
        close|c)
            change_issue_state "$project_repo" "$provider" "close" "open"
            ;;
        open|o)
            change_issue_state "$project_repo" "$provider" "open" "closed"
            ;;
        edit|e)
            edit_issue "$project_repo" "$provider"
            ;;
        *)
            echo "Invalid action for issues. Valid actions are 'new', 'ls', 'close', 'reopen', 'edit'."
            return 1
            ;;
    esac
}

function list_issues {
    local repo="$1"
    local provider="$2"
    
    local endpoint_list=$(g_get_api_info "$provider" "issues.list.endpoint")
    local issues=$(call_api "$provider" "GET" "${endpoint_list//:repo/$repo}")

    if [[ $? -ne 0 || -z "$issues" ]]; then
        echo "Error fetching issues or no issues available."
        return 1
    fi

    if echo "$issues" | jq empty 2>/dev/null; then
        local selection=$(echo "$issues" | jq -r '.[] | "\(.number) \(.title)"' | fzf $fzf_geometry)
        if [[ -n "$selection" ]]; then
            local issue_id=$(echo "$selection" | awk '{print $1}')
            show_issue_details "$repo" "$provider" "$issue_id"
        fi
    else
        echo "Invalid response format. Please check API validity and credentials."
    fi
}

function show_issue_details {
    local repo="$1"
    local provider="$2"
    local issue_number="$3"

    local endpoint_issue=$(g_get_api_info "$provider" "issues.update.endpoint")
    endpoint_issue="${endpoint_issue/:repo/$repo}"
    endpoint_issue="${endpoint_issue/:issue_number/$issue_number}"

    local issue=$(call_api "$provider" "GET" "$endpoint_issue")

    if [[ $? -ne 0 || -z "$issue" || "$(echo "$issue" | jq -r '.message')" == "Not Found" ]]; then
        echo "Error fetching issue details or issue not found. Check API response and authentication."
        return 1
    fi

    local project_name=$(echo "$repo" | cut -d/ -f2)
    local full_repo=$repo
    local url=$(echo "$issue" | jq -r '.html_url // "null"')
    local title=$(echo "$issue" | jq -r '.title // "null"')
    local author=$(echo "$issue" | jq -r '.user.login // "null"')
    local created_at=$(echo "$issue" | jq -r '.created_at // "null"')
    local updated_at=$(echo "$issue" | jq -r '.updated_at // "null"')
    local labels=$(echo "$issue" | jq -r '.labels | map(.name) | join(", ") // "None"')
    local comments_count=$(echo "$issue" | jq -r '.comments // "0"')
    local body=$(echo "$issue" | jq -r '.body // "No description available." | @text' | fold -s -w 80 | sed 's/^/    > /')

    local comments_json=$(fetch_issue_comments "$repo" "$provider" "$issue_number")

    local blue="\033[34m"
    local magenta="\033[35m"
    local reset="\033[0m"

    local label_width=12

    printf "${blue}%-*s${reset} %s\n" $label_width "Project:" "$project_name"
    printf "${blue}%-*s${reset} %s\n" $label_width "Repo:" "$full_repo"
    echo -e "${magenta}------------------------------------${reset}"
    printf "${blue}%-*s${reset} %s\n" $label_width "Issue ID:" "$issue_number"
    printf "${blue}%-*s${reset} %s\n" $label_width "Url:" "$url"
    echo -e "${magenta}------------------------------------${reset}"
    printf "${blue}%-*s${reset} %s\n" $label_width "Title:" "$title"
    printf "${blue}%-*s${reset} %s\n" $label_width "Author:" "$author"
    printf "${blue}%-*s${reset} %s\n" $label_width "Creation:" "$created_at"
    printf "${blue}%-*s${reset} %s\n" $label_width "Modif:" "$updated_at"
    printf "${blue}%-*s${reset} %s\n" $label_width "Labels:" "$labels"
    printf "${blue}%-*s${reset} %s\n" $label_width "Comments:" "$comments_count"
    printf "${blue}%-*s${reset}\n" $label_width "Description:"
    echo -e "$body"
    echo -e "${magenta}------------------------------------${reset}"

    if [[ -n "$comments_json" && "$(echo "$comments_json" | jq empty 2>/dev/null)" == "" ]]; then
        echo "No comments."
    else
        echo "$comments_json" | jq -c '.[]' | nl -w1 -s'. ' | while read -r line; do
            local comment_index=$(echo "$line" | cut -d'.' -f1)
            local comment_json=$(echo "$line" | cut -d'.' -f2-)
            local comment_body=$(echo "$comment_json" | jq -r '.body // "Empty comment" | @text' | fold -s -w 80 | sed 's/^/    > /')

            echo -e "${magenta}------------------------------------${reset}"
            echo "Comment #$comment_index"
            echo "$comment_body"
        done
    fi
}

function fetch_issue_comments {
    local repo="$1"
    local provider="$2"
    local issue_id="$3"

    local endpoint_comments=$(g_get_api_info "$provider" "issues.comment.endpoint")
    call_api "$provider" "GET" "${endpoint_comments//:repo/$repo}/$issue_id/comments"
}


function create_new_issue {
    local repo="$1"
    local provider="$2"

    echo "Fetching existing labels..."
    local labels=$(fetch_labels "$repo" "$provider")
    local label_names=$(echo "$labels" | jq -r '.[].name')

    local blue="\033[34m"
    local reset="\033[0m" 

    echo "${blue}Title:${reset}"
    read -e -r -p "> " title
    echo "${blue}Description:${reset}"
    read -e -r -p "> " description
    echo "${blue}Labels:"
    selected_labels=$(echo "$label_names" | fzf --multi $fzf_geometry)

    selected_labels_json=$(echo "$selected_labels" | jq --raw-input --slurp 'split("\n") | map(select(length > 0))')

    local endpoint_create=$(g_get_api_info "$provider" "issues.create.endpoint")
    local json_payload="{\"title\": \"${title}\", \"body\": \"${description}\", \"labels\": ${selected_labels_json}}"

    local response=$(call_api "$provider" "POST" "${endpoint_create//:repo/$repo}" "$json_payload")

    echo "Debug: JSON Payload - $json_payload"

    if [[ $? -eq 0 && "$(echo "$response" | jq -r '.message')" == "null" ]]; then
        echo "ok: The issue has been created."
    else
        echo "error: Failed to create the issue. Response: $response"
    fi
}

function fetch_labels {
    local repo="$1"
    local provider="$2"

    local endpoint_list=$(g_get_api_info "$provider" "labels.list.endpoint")
    call_api "$provider" "GET" "${endpoint_list//:repo/$repo}"
}

function edit_issue {
    local repo="$1"
    local provider="$2"

    local blue="\033[34m"
    local reset="\033[0m"

    local endpoint_list=$(g_get_api_info "$provider" "issues.list.endpoint")
    local issues=$(call_api "$provider" "GET" "${endpoint_list//:repo/$repo}")

    if [[ $? -ne 0 || -z "$issues" ]]; then
        echo "Error fetching issues or no issues available."
        return 1
    fi

    local selection=$(echo "$issues" | jq -r '.[] | "\(.number) \(.title)"' | fzf $fzf_geometry)
    
    local issue_number=$(echo "$selection" | awk '{print $1}')
    if [[ -z "$issue_number" ]]; then
        echo "No issue selected."
        return 1
    fi

    local endpoint_issue=$(g_get_api_info "$provider" "issues.update.endpoint")
    endpoint_issue="${endpoint_issue/:repo/$repo}"
    endpoint_issue="${endpoint_issue/:issue_number/$issue_number}"
    
    local issue=$(call_api "$provider" "GET" "$endpoint_issue")

    if [[ $? -ne 0 || -z "$issue" || "$(echo "$issue" | jq -r '.message')" == "Not Found" ]]; then
        echo "Error fetching issue details or issue not found. Check API response and authentication."
        echo "Debug: API Response - $issue"
        return 1
    fi

    local current_title=$(echo "$issue" | jq -r '.title // "No Title"')
    local current_body=$(echo "$issue" | jq -r '.body // "No description available."')
    local current_labels=$(echo "$issue" | jq -r '[.labels[].name] | join(", ")')

    echo -e "${blue}New title:${reset}"
    echo -n "> "
    read -e -r new_title
    new_title=${new_title:-$current_title}

    echo -e "${blue}New description:${reset}"
    echo -n "> "
    read -e -r new_body
    new_body=${new_body:-$current_body}

    local labels=$(fetch_labels "$repo" "$provider")
    local label_names=$(echo "$labels" | jq -r '.[].name')

    echo -e "${blue}New Labels:${reset}"
    local selected_labels=$(echo "$label_names" | fzf --multi $fzf_geometry)
    local selected_labels_json=$(echo "$selected_labels" | jq --raw-input --slurp 'split("\n") | map(select(length > 0))')

    # Update issue
    local data="{\"title\": \"$new_title\", \"body\": \"$new_body\", \"labels\": $selected_labels_json}"
    local response=$(call_api "$provider" "PATCH" "$endpoint_issue" "$data")

    if [[ $? -eq 0 && "$(echo "$response" | jq -r '.message')" == "null" ]]; then
        echo "ok: The issue has been updated."
    else
        echo "error: Failed to update the issue. Response: $response"
    fi
}

function change_issue_state {
    local repo="$1"
    local provider="$2"
    local new_state="$3"
    local state_label="$4"

    # Fetch issues based on the desired current state (open or closed)
    local endpoint_list=$(g_get_api_info "$provider" "issues.list.endpoint")
    local current_issues=$(call_api "$provider" "GET" "${endpoint_list//:repo/$repo}?state=$state_label")

    if [[ $? -ne 0 || -z "$current_issues" ]]; then
        echo "Error fetching $state_label issues or no $state_label issues available."
        return 1
    fi

    if ! echo "$current_issues" | jq -e '.[]' > /dev/null 2>&1; then
        echo "Error: The response is not a valid JSON array, or no issues present."
        return 1
    fi

    local selections=$( echo "$current_issues" | jq -r '.[] | "\(.number) \(.title)"' | fzf --multi $fzf_geometry)

    # Validate selections
    if [[ -z "$selections" ]]; then
        echo "No issues selected."
        return 0
    fi

    # Change state for each selected issue
    echo "$selections" | while read -r selection; do
        local issue_number=$(echo "$selection" | awk '{print $1}')
        if [[ -z "$issue_number" ]]; then
            echo "Invalid issue selection."
            continue
        fi

        local endpoint_issue=$(g_get_api_info "$provider" "issues.update.endpoint")
        endpoint_issue="${endpoint_issue/:repo/$repo}"
        endpoint_issue="${endpoint_issue/:issue_number/$issue_number}"

        local data="{\"state\": \"$new_state\"}"
        local response=$(call_api "$provider" "PATCH" "$endpoint_issue" "$data")

        if [[ $? -eq 0 && "$(echo "$response" | jq -r '.state')" == "$new_state" ]]; then
            echo "ok: Issue #$issue_number has been ${new_state}d."
        else
            echo "error: Failed to change state for issue #$issue_number. Response: $response"
        fi
    done
}
