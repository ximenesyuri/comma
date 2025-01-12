function issue_ {
    PROJ_DEPS 
    local proj_="$1"
    local act_="$2"
    shift 2

    if is_error_ $(proj_allow issue $proj_); then 
        return 1
    fi

    local repo_=$(proj_get repo $proj_)
    local prov_=$(proj_get prov $proj_)

    case "$act_" in
        new|n)
            new_issue "$repo_" "$prov_"
            ;;
        info|inf|i)
            info_issues "$repo_" "$prov_" "$@"
            ;;
        list|ls|l)
            source $PROJ_DIR/utils/url.sh
            list_issues "$repo_" "$prov_" "$@"
            ;;
        close|C)
            change_state "$repo_" "$prov_" "closed"
            ;;
        comment|com|c)
            source $PROJ_DIR/servs/issue_comment.sh
            if is_error_ $(proj_allow comments $proj_); then
                return 1
            fi 
            comments_ "$repo_" "$prov_" "$@"
            ;;
        open|o)
            change_state "$repo_" "$prov_" "open"
            ;;
        edit|e)
            edit_issue "$repo_" "$prov_"
            ;; 
        *)
            error_ "Issue actions: 'new', 'info', 'list', 'close', 'open', 'edit', 'browse'."
            return 1
            ;;
    esac
}

function filter_issues {
    local repo_="$1"
    local prov_="$2"
    shift 2

    local state_filter="state=open"
    local label_filter=""
    local name_filter=""
    local desc_filter=""
    local owner_filter=""
    local assign_filter=""

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
            -a|--assign)
                assign_filter="$2"
                shift
                ;;
            -c|--close)
                state_filter='state=closed'
                ;;
            -r|--reopen)
                state_filter='state=all'
                ;;
            --all)
                state_filter='state=all'
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
        shift
    done

    local endpoint=$(endpoint_ "issue" "$prov_" "$repo_" "list")
    if is_error_ "$endpoint"; then
        return 1
    fi
    local method=$(method_ "issues" "$prov_" "list")
    local issues=$(call_api "$prov_" "$method" "$endpoint?$state_filter")

    if [[ $? -ne 0 || -z "$issues" ]]; then
        error_ "Could not fetch issues."
        return 1
    fi

    local jq_filter=".[]"
    [[ -n $label_filter ]] && jq_filter+=" | select(.labels[]?.name? | test(\"$label_filter\"))"
    [[ -n $name_filter ]] && jq_filter+=" | select(.title? | test(\"$name_filter\"))"
    [[ -n $desc_filter ]] && jq_filter+=" | select(.body? | test(\"$desc_filter\"))"
    [[ -n $owner_filter ]] && jq_filter+=" | select(.user.login? | test(\"$owner_filter\"))"
    [[ -n $assign_filter ]] && jq_filter+=" | select(.assignee.login? | test(\"$assign_filter\"))"

    filtered_issues=$(echo "$issues" | jq -c "[$jq_filter]")

    if [[ -z "$filtered_issues" || "$filtered_issues" == "[]" ]]; then
        echo "No matching issues found."
        return 1
    fi

    echo "$filtered_issues"
}

function list_issues {
    local repo_="$1"
    local prov_="$2"

    local issues_json=$(filter_issues "$repo_" "$prov_" --all)
    if is_error_ "$issues_json"; then
        return 1
    fi

    local open_issues=$(echo "$issues_json" | jq '[.[] | select(.state=="open")] | length')
    local closed_issues=$(echo "$issues_json" | jq '[.[] | select(.state=="closed")] | length')
    local total_issues=$(echo "$issues_json" | jq 'length')

    entry_ "proj" "$(basename "$repo_")"
    entry_ "repo" "$repo_"
    entry_ "url" "$(url_ "issue" "$prov_" "$repo_")"
    entry_ "open" "$open_issues"
    entry_ "closed" "$closed_issues"
    entry_ "total" "$total_issues"
    line_

    echo "$issues_json" | jq -c '.[]' | while read -r issue; do
        local number=$(echo "$issue" | jq -r '.number')
        local author=$(echo "$issue" | jq -r '.user.login')
        local title=$(echo "$issue" | jq -r '.title')
        local labels=$(echo "$issue" | jq -r '.labels | map(.name) | join(", ") // "None"')
        local comments=$(echo "$issue" | jq -r '.comments')

        entry_ "issue" "#$number"
        entry_ "author" "$author"
        entry_ "title" "$title"
        entry_ "labels" "$labels"
        entry_ "comments" "#$comments"
        line_
    done
}

function info_issues {
    local repo_="$1"
    local prov_="$2"

    local filtered_issues=$(filter_issues "$repo_" "$prov_")
    if is_error_ "$filtered_issues"; then
        return 1
    fi

    local selection=$(echo "$filtered_issues" | jq -r '.[] | "\(.number) \(.title)"' | fzf $FZF_GEOMETRY)
    if [[ -n "$selection" ]]; then
        local id_=$(echo "$selection" | awk '{print $1}')
        show_issue "$repo_" "$prov_" "$id_"
    else
        error_ "No issues selected."
    fi
}

function show_issue {
    local repo_="$1"
    local prov_="$2"
    local number_="$3"

    local endpoint=$(endpoint_ "issue" "$prov_" "$repo_" "get" "$number_")
    if is_error_ "$endpoint"; then
        return 1
    fi
    local method=$(method_ "issues" "$prov_" "get")
    local issue_=$(call_api "$prov_" "$method" "$endpoint")
    if is_error_ "$issue_"; then
        return 1
    fi

    if [[ $? -ne 0 || -z "$issue_" || "$(echo "$issue_" | jq -r '.message')" == "Not Found" ]]; then
        error_ "Could not fetch issue details."
        return 1
    fi

    local proj_=$(echo "$repo_" | cut -d/ -f2)
    local full_repo=$repo_
    local url=$(echo "$issue_" | jq -r '.html_url // "null"')
    local title=$(echo "$issue_" | jq -r '.title // "null"')
    local author=$(echo "$issue_" | jq -r '.user.login // "null"')
    local created_at=$(echo "$issue_" | jq -r '.created_at // "null"')
    local updated_at=$(echo "$issue_" | jq -r '.updated_at // "null"')
    local labels=$(echo "$issue_" | jq -r '.labels | map(.name) | join(", ") // "None"')
    local comments_count=$(echo "$issue_" | jq -r '.comments // "0"')
    local body=$(echo "$issue_" | jq -r '.body // "No description available." | @text' )
    local assignee=$(echo "$issue_" | jq -r '.assignee.login // "none"')

    local comments_json=$(fetch_comments "$repo_" "$prov_" "$number_")

    entry_ "project" "$proj_"
    entry_ "repo" "$full_repo"
    line_
    entry_ "ID" "$number_"
    entry_ "url" "$url"
    line_
    entry_ "title" "$title"
    entry_ "author" "$author"
    entry_ "creation" "$created_at"
    entry_ "modif" "$updated_at"
    entry_ "labels" "$labels"
    entry_ "assignee" "$assignee"
    entry_ "comments" "$comments_count"
    entry_ "description" " "
    print_ "$body" 
    line_

    if [[ -n "$comments_json" && "$(echo "$comments_json" | jq empty 2>/dev/null)" == "" ]]; then
        echo "No comments."
    else
        echo "$comments_json" | jq -c '.[]' | nl -w1 -s'. ' | while read -r line; do
            local comment_index=$(echo "$line" | cut -d'.' -f1)
            local comment_json=$(echo "$line" | cut -d'.' -f2-)
            local comment_body=$(echo "$comment_json" | jq -r '.body // "Empty comment" | @text' | fold_ | sed 's/^/    | /')

            line_
            echo "Comment #$comment_index"
            echo "$comment_body"
        done
    fi
}

function fetch_comments {
    local repo_="$1"
    local prov_="$2"
    local id_="$3"

    local endpoint=$(endpoint_ "issue" "$prov_" "$repo_" "comments")
    local method=$(method_ "issues" "$prov_" "comments")
    call_api "$prov_" "$method" "${endpoint//:issue_number/$id_}"
}

function new_issue {
    local repo_="$1"
    local prov_="$2"
    local labels=$(fetch_labels "$repo_" "$prov_")
    local label_names=$(echo "$labels" | jq -r '.[].name')

    primary_ "title:"
    input_ -v title
    line_
    primary_ "description:"
    input_ -e md -v description
    line_
    primary_ "labels:"
    selected_labels=$(echo "$label_names" | fzf --multi $FZF_GEOMETRY)

    selected_labels_json=$(echo "$selected_labels" | jq --raw-input --slurp 'split("\n") | map(select(length > 0))')

    primary_ "assign:"
    input_ -v assign_user

    local endpoint=$(endpoint_ "issue" "$prov_" "$repo_" "create")
    local method=$(method_ "issues" "$prov_" "create")
    local json_payload=$(issue_payload "$prov_" "create" title="$title" body="$description" labels="$selected_labels_json" assignee="$assign_user")

    local response=$(call_api "$prov_" "$method" "$endpoint" "$json_payload")

    if response_ "$response"; then
        done_ "The issue has been created."
    else
        error_ "Failed to create the issue."
        error_ "Response: $response"
    fi
}

function fetch_labels {
    local repo_="$1"
    local prov_="$2"

    local endpoint=$(endpoint_ "label" "$prov_" "$repo_" "list")
    local method=$(method_ "labels" "$prov_" "list")
    call_api "$prov_" "$method" "$endpoint"
}

function edit_issue {
    local repo_="$1"
    local prov_="$2"

    local list_endpoint=$(endpoint_ "issue" "$prov_" "$repo_" "list")
    local method_get=$(method_ "issues" "$prov_" "list")
    local issues=$(call_api "$prov_" "$method_get" "$list_endpoint")

    if [[ $? -ne 0 || -z "$issues" ]]; then
        error_ "Could not fetch issues."
        return 1
    fi

    local selection=$(echo "$issues" | jq -r '.[] | "\(.number) \(.title)"' | fzf $FZF_GEOMETRY)
    local number_=$(echo "$selection" | awk '{print $1}')
    if [[ -z "$number_" ]]; then
        echo "No issue selected."
        return 1
    fi
    local update_endpoint=$(endpoint_ "issue" "$prov_" "$repo_" "update" "$number_")
    local method_get=$(method_ "issues" "$prov_" "get")
    local issue=$(call_api "$prov_" "$method_get" "$update_endpoint")

    if [[ $? -ne 0 || -z "$issue" || "$(echo "$issue" | jq -r '.message')" == "Not Found" ]]; then
        error_ "Could not fetch issue details."
        return 1
    fi

    local current_title=$(echo "$issue" | jq -r '.title // "No Title"')
    local current_body=$(echo "$issue" | jq -r '.body // "No description available."')
    local current_labels=$(echo "$issue" | jq -r '[.labels[]?.name] | join(", ") // "null"')
    local current_assignee=$(echo "$issue" | jq -r '.assignee?.login // ""')

    primary -c "title:" -n "$current_title"
    primary_ "new title:"
    input_ -v new_title
    new_title=${new_title:-$current_title}

    line_
    primary -c "desc:" -n "$(fold_ "$current_body")"
    primary_ "new desc:"
    input_ -e md -v new_body
    new_body=${new_body:-$current_body}

    line_
    primary -c "labels:" -n "$current_labels"
    primary_ "new labels:"

    local labels=$(fetch_labels "$repo_" "$prov_")
    local label_names=$(echo "$labels" | jq -r '.[].name')
    local selected_labels=$(echo "$label_names" | fzf --multi $FZF_GEOMETRY)
    local selected_labels_json=$(echo "$selected_labels" | jq --raw-input --slurp 'split("\n") | map(select(length > 0))')

    line_
    primary -c "assignee:" -n "$current_assignee"
    primary_ -c "assignee:" -n "(blank to unassign)"
    input_ -v new_assignee

    local json_assignee_value="null"
    if [[ -n "$new_assignee" ]]; then
        json_assignee_value="\"$new_assignee\""
    fi

    local method_patch=$(method_ "issues" "$prov_" "update")
    local data_=$(issue_payload "$prov_" "update" title="$new_title" body="$new_body" labels="$selected_labels_json" assignee="$json_assignee_value")

    local response=$(call_api "$prov_" "$method_patch" "$update_endpoint" "$data_")

    if response_ "$response"; then
        done_ "The issue has been edited."
    else
        error_ "Failed to edit the issue."
        error_ "Response: $response"
    fi
}

function change_state {
    local repo_="$1"
    local prov_="$2"
    local state_new="$3"

    local list_endpoint=$(endpoint_ "issue" "$prov_" "$repo_" "list")
    local method_get=$(method_ "issues" "$prov_" "list")
    local issues_=$(call_api "$prov_" "$method_get" "$list_endpoint?state=all")

    if [[ $? -ne 0 || -z "$issues_" ]]; then
        error_ "Could not fetch issue state."
        return 1
    fi

    if ! echo "$issues_" | jq -e '.[]' > /dev/null 2>&1; then
        error_ "The response is not a valid JSON."
        return 1
    fi

    local selections=$( echo "$issues_" | jq -r '.[] | "\(.number) \(.title)"' | fzf --multi $FZF_GEOMETRY)

    if [[ -z "$selections" ]]; then
        error_ "No issues selected."
        return 0
    fi

    echo "$selections" | while read -r selection; do
        local number_=$(echo "$selection" | awk '{print $1}')
        if [[ -z "$number_" ]]; then
            error_ "Invalid issue selection."
            continue
        fi

        local endpoint=$(endpoint_ "issue" "$prov_" "$repo_" "update" "$number_")
        local method=$(method_ "issues" "$prov_" "update")

        local data_=$(issue_payload "$prov_" "update" state="$state_new")
        local response=$(call_api "$prov_" "$method" "$endpoint" "$data_")

        if response_ "$response"; then
            done_ "The issue status has been changed."
        else
            error_ "Failed to change issue status."
            error_ "Response: $response"
        fi
    done
}
