function issues_ {
    local project_name="$1"
    local action="$2"
    shift 2

    local project_config
    project_config=$(get_proj "$project_name")

    if [[ -z "$project_config" || "$project_config" == "null" ]]; then
        error_ "Project '$project_name' not found."
        return 1
    fi

    if [[ $(yq e '.server.issues' <<< "$project_config") != "true" ]]; then
        error_ "Project '$project_name' does not support issues."
        return 2
    fi

    local project_repo=$(yq e '.server.repo' <<< "$project_config")
    local provider=$(yq e '.server.provider' <<< "$project_config")

    case "$action" in
        new|n)
            new_issue "$project_repo" "$provider"
            ;;
        ls)
            list_issues "$project_repo" "$provider" "$@"
            ;;
        close|c)
            change_state "$project_repo" "$provider" "close" "open"
            ;;
        comment|com|C)
            source ${BASH_SOURCE%/*}/issue_comment.sh
            comments_ "$project_name" "$provider" "$@"
            ;;
        open|o)
            change_state "$project_repo" "$provider" "open" "closed"
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
    shift 2

    # Default filter state
    local state_filter='state=open'
    local label_filter=""
    local name_filter=""
    local desc_filter=""
    local owner_filter=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -l|--label|--labels)
                label_filter="$2"
                shift
                ;;
            -n|--name|--title)
                name_filter="$2"
                shift
                ;;
            -d|--desc|--description)
                desc_filter="$2"
                shift
                ;;
            -o|--owner)
                owner_filter="$2"
                shift
                ;;
            -c|--close)
                state_filter='state=closed'
                ;;
            -r|--reopen)
                state_filter='state=all'
                ;;
            -a|--all)
                state_filter='state=all'
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
        shift
    done

    local endpoint_list=$(get_api "$provider" "issues.list.endpoint")
    local issues=$(call_api "$provider" "GET" "${endpoint_list//:repo/$repo}?$state_filter")

    if [[ $? -ne 0 || -z "$issues" ]]; then
        error_ "Could not fetch issues."
        return 1
    fi

    local jq_filter=".[]"
    [[ -n $label_filter ]] && jq_filter+=" | select((.labels[]?.name | test(\"$label_filter\")) // false)"
    [[ -n $name_filter ]] && jq_filter+=" | select((.title | test(\"$name_filter\")) // false)"
    [[ -n $desc_filter ]] && jq_filter+=" | select((.body | test(\"$desc_filter\")) // false)"
    [[ -n $owner_filter ]] && jq_filter+=" | select((.user.login | test(\"$owner_filter\")) // false)"

    local filtered_issues=$(echo "$issues" | jq -c "[$jq_filter]")

    if [[ -z "$filtered_issues" || "$filtered_issues" == "[]" ]]; then
        echo "No matching issues found."
        return 1
    fi

    local selection=$(echo "$filtered_issues" | jq -r '.[] | "\(.number) \(.title)"' | fzf $FZF_GEOMETRY)
    if [[ -n "$selection" ]]; then
        local issue_id=$(echo "$selection" | awk '{print $1}')
        show_issue "$repo" "$provider" "$issue_id"
    else
        echo "No issues selected."
    fi
}

function show_issue {
    local repo="$1"
    local provider="$2"
    local issue_number="$3"

    local endpoint_issue=$(get_api "$provider" "issues.update.endpoint")
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
    local body=$(echo "$issue" | jq -r '.body // "No description available." | @text' | fold_ | sed 's/^/    > /')

    local comments_json=$(fetch_comments "$repo" "$provider" "$issue_number")
 

    printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "Project:" "$project_name"
    printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "Repo:" "$full_repo"
    line_
    printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "Issue ID:" "$issue_number"
    printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "Url:" "$url"
    line_
    printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "Title:" "$title"
    printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "Author:" "$author"
    printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "Creation:" "$created_at"
    printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "Modif:" "$updated_at"
    printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "Labels:" "$labels"
    printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "Comments:" "$comments_count"
    printf "${PRIMARY}%-*s${RESET}\n" $LABEL_WIDTH "Description:"
    echo -e "$body"
    line_

    if [[ -n "$comments_json" && "$(echo "$comments_json" | jq empty 2>/dev/null)" == "" ]]; then
        echo "No comments."
    else
        echo "$comments_json" | jq -c '.[]' | nl -w1 -s'. ' | while read -r line; do
            local comment_index=$(echo "$line" | cut -d'.' -f1)
            local comment_json=$(echo "$line" | cut -d'.' -f2-)
            local comment_body=$(echo "$comment_json" | jq -r '.body // "Empty comment" | @text' | fold_ | sed 's/^/    > /')

            line_
            echo "Comment #$comment_index"
            echo "$comment_body"
        done
    fi
}

function fetch_comments {
    local repo="$1"
    local provider="$2"
    local issue_id="$3"

    local endpoint_comments=$(get_api "$provider" "issues.comment.endpoint")
    call_api "$provider" "GET" "${endpoint_comments//:repo/$repo}/$issue_id/comments"
}

function new_issue {
    local repo="$1"
    local provider="$2" 
    local labels=$(fetch_labels "$repo" "$provider")
    local label_names=$(echo "$labels" | jq -r '.[].name') 

    primary_ "Title:"
    input_ -v title
    line_
    primary_ "Description:"
    input_ -e md -v description
    line_
    primary_ "Labels:"
    selected_labels=$(echo "$label_names" | fzf --multi $FZF_GEOMETRY)

    selected_labels_json=$(echo "$selected_labels" | jq --raw-input --slurp 'split("\n") | map(select(length > 0))')

    local endpoint_create=$(get_api "$provider" "issues.create.endpoint")
    local json_payload="{\"title\": \"${title}\", \"body\": ${description}, \"labels\": ${selected_labels_json}}"

    local response=$(call_api "$provider" "POST" "${endpoint_create//:repo/$repo}" "$json_payload")

    if response_ $response; then 
        done_ "The issue has been created."
    else
        error_ "Failed to create the issue."
        error_ "Response: $response"
    fi

}

function fetch_labels {
    local repo="$1"
    local provider="$2"

    local endpoint_list=$(get_api "$provider" "labels.list.endpoint")
    call_api "$provider" "GET" "${endpoint_list//:repo/$repo}"
}

function edit_issue {
    local repo="$1"
    local provider="$2"

    local endpoint_list=$(get_api "$provider" "issues.list.endpoint")
    local issues=$(call_api "$provider" "GET" "${endpoint_list//:repo/$repo}")

    if [[ $? -ne 0 || -z "$issues" ]]; then
        echo "Error fetching issues or no issues available."
        return 1
    fi

    local selection=$(echo "$issues" | jq -r '.[] | "\(.number) \(.title)"' | fzf $FZF_GEOMETRY)
    local issue_number=$(echo "$selection" | awk '{print $1}')
    if [[ -z "$issue_number" ]]; then
        echo "No issue selected."
        return 1
    fi

    local endpoint_issue=$(get_api "$provider" "issues.update.endpoint")
    endpoint_issue="${endpoint_issue/:repo/$repo}"
    endpoint_issue="${endpoint_issue/:issue_number/$issue_number}"

    local issue=$(call_api "$provider" "GET" "$endpoint_issue")

    local current_title=$(echo "$issue" | jq -r '.title // "No Title"')
    local current_body=$(echo "$issue" | jq -r '.body // "No description available."')
    local current_labels=$(echo "$issue" | jq -r '[.labels[].name] | join(", ") // "null"')

    echo -e ${PRIMARY}Title:${RESET} "$current_title"
    primary_ "New Title:"
    input_ -v new_title
    new_title=${new_title:-$current_title}

    line_
    echo -e ${PRIMARY}Description:${RESET} $(fold_ "$current_body")
    primary_ "New Description:"
    input_ -e md -v new_body
    new_body=${new_body:-$current_body}

    line_
    echo -e ${PRIMARY}Labels:${RESET} $current_labels
    primary_ "New Labels:"

    local labels=$(fetch_labels "$repo" "$provider")
    local label_names=$(echo "$labels" | jq -r '.[].name')
    local selected_labels=$(echo "$label_names" | fzf --multi $FZF_GEOMETRY)
    local selected_labels_json=$(echo "$selected_labels" | jq --raw-input --slurp 'split("\n") | map(select(length > 0))')  

    local data="{\"title\": \"$new_title\", \"body\": $new_body, \"labels\": $selected_labels_json}"
    local response=$(call_api "$provider" "PATCH" "$endpoint_issue" "$data")

    if response_ $response; then 
        done_ "The issue has been edited."
    else
        error_ "Failed to edit the issue."
        error_ "Response: $response"
    fi 
}

function change_state {
    local repo="$1"
    local provider="$2"
    local new_state="$3"
    local state_label="$4"

    local endpoint_list=$(get_api "$provider" "issues.list.endpoint")
    local current_issues=$(call_api "$provider" "GET" "${endpoint_list//:repo/$repo}?state=$state_label")

    if [[ $? -ne 0 || -z "$current_issues" ]]; then
        echo "Error fetching $state_label issues or no $state_label issues available."
        return 1
    fi

    if ! echo "$current_issues" | jq -e '.[]' > /dev/null 2>&1; then
        echo "Error: The response is not a valid JSON array, or no issues present."
        return 1
    fi

    local selections=$( echo "$current_issues" | jq -r '.[] | "\(.number) \(.title)"' | fzf --multi $FZF_GEOMETRY)

    if [[ -z "$selections" ]]; then
        echo "No issues selected."
        return 0
    fi

    echo "$selections" | while read -r selection; do
        local issue_number=$(echo "$selection" | awk '{print $1}')
        if [[ -z "$issue_number" ]]; then
            echo "Invalid issue selection."
            continue
        fi

        local endpoint_issue=$(get_api "$provider" "issues.update.endpoint")
        endpoint_issue="${endpoint_issue/:repo/$repo}"
        endpoint_issue="${endpoint_issue/:issue_number/$issue_number}"

        local data="{\"state\": \"$new_state\"}"
        local response=$(call_api "$provider" "PATCH" "$endpoint_issue" "$data")

        if response_ $response; then 
            done_ "The issue status has been changed."
        else
            error_ "Failed to change issue status."
            error_ "Response: $response"
        fi 
    done
}
