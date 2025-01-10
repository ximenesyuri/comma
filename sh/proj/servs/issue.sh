function issue_ {     
    local proj_="$1"
    local act_="$2" 
    shift 2 

    if ! $(proj_allow issue $proj_);then
        error_ "Project '$proj_' does not allow issues."
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
            list_issues "$repo_" "$prov_" "$@"
            ;;
        close|c)
            change_state "$repo_" "$prov_" "close" "open"
            ;;
        comment|com|C)
            source ${BASH_SOURCE%/*}/issue_comment.sh
            comments_ "$proj_" "$prov_" "$@"
            ;;
        open|o)
            change_state "$repo_" "$prov_" "open" "closed"
            ;;
        edit|e)
            edit_issue "$repo_" "$prov_"
            ;;
        browse|b)
            dir_=${BASH_SOURCE%/*}
            dir_=${dir_%/*}
            source $dir_/utils/url.sh
            browse_issue "$repo_" "$prov_"  
            ;;
        Browse|BROWSE|B)
            dir_=${BASH_SOURCE%/*}
            dir_=${dir_%/*}
            source $dir_/utils/url.sh
            BROWSE_issue "$repo_" "$prov_"
            ;;
        *)
            error_ "Issue actions: 'new', 'ls', 'close', 'reopen', 'edit'."
            return 1
            ;;
    esac
}

function filter_issues {
    local repo_="$1"
    local prov_="$2"
    shift 2

    local state_filter='state=open'
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

    local endpoint_=$(get_api "$prov_" ".issues.list.endpoint")
    local method_=$(get_api "$prov_" ".issues.list.method")
    local issues=$(call_api "$prov_" "$method_" "${endpoint_//:repo/$repo_}?$state_filter")

    if [[ $? -ne 0 || -z "$issues" ]]; then
        error_ "Could not fetch issues."
        return 1
    fi

    local jq_filter=".[]"
    [[ -n $label_filter ]] && jq_filter+=" | select((.labels[]?.name | test(\"$label_filter\")) // false)"
    [[ -n $name_filter ]] && jq_filter+=" | select((.title | test(\"$name_filter\")) // false)"
    [[ -n $desc_filter ]] && jq_filter+=" | select((.body | test(\"$desc_filter\")) // false)"
    [[ -n $owner_filter ]] && jq_filter+=" | select((.user.login | test(\"$owner_filter\")) // false)"
    [[ -n $assign_filter ]] && jq_filter+=" | select((.assignee.login | test(\"$assign_filter\")) // false)"

    filtered_issues=$(echo "$issues" | jq -c "[$jq_filter]")

    if [[ -z "$filtered_issues" || "$filtered_issues" == "[]" ]]; then
        echo "No matching issues found."
        return 1
    fi

    echo "$filtered_issues"
}

function info_issues(){
    repo_="$1"
    prov_="$2"

    filtered_issues=$(filter_issues $repo_ $prov_)
    if is_error_ "$filtered_issues"; then
        echo "$filtered_issues"
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

    local endpoint_=$(get_api "$prov_" ".issues.update.endpoint")
    endpoint_="${endpoint_/:repo/$repo_}"
    endpoint_="${endpoint_/:issue_number/$number_}"
    local method_=$(get_api "$prov_" ".issues.update.method")

    local issue_=$(call_api "$prov_" "GET" "$endpoint_")

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
    local body=$(echo "$issue_" | jq -r '.body // "No description available." | @text' | fold_ | sed 's/^/    > /')
    local assignee=$(echo "$issue_" | jq -r '.assignee.login // "none"')

    local comments_json=$(fetch_comments "$repo_" "$prov_" "$number_")

    printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "Project:" "$proj_"
    printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "Repo:" "$full_repo"
    line_
    printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "Issue ID:" "$number_"
    printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "Url:" "$url"
    line_
    printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "Title:" "$title"
    printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "Author:" "$author"
    printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "Creation:" "$created_at"
    printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "Modif:" "$updated_at"
    printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "Labels:" "$labels"
    printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "Assignee:" "$assignee"
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
    local repo_="$1"
    local prov_="$2"
    local id_="$3"

    local endpoint_=$(get_api "$prov_" ".issues.comment.endpoint")
    local method_=$(get_api "$prov_" ".issues.comment.method")
    call_api "$prov_" "$method_" "${endpoint_//:repo/$repo_}/id_/comments"
}

function new_issue {
    local repo_="$1"
    local prov_="$2" 
    local labels=$(fetch_labels "$repo_" "$prov_")
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

    primary_ "Assign:"
    input_ -v assign_user

    local endpoint_=$(get_api "$prov_" ".issues.create.endpoint")
    local method_=$(get_api "$prov_" ".issues.create.method")
    local json_payload="{\"title\": \"${title}\", \"body\": ${description}, \"labels\": ${selected_labels_json}, \"assignee\": \"${assign_user}\"}"

    local response=$(call_api "$prov_" "POST" "${endpoint_//:repo/$repo_}" "$json_payload")

    if response_ $response; then 
        done_ "The issue has been created."
    else
        error_ "Failed to create the issue."
        error_ "Response: $response"
    fi

}

function fetch_labels {
    local repo_="$1"
    local prov_="$2"

    local endpoint_=$(get_api "$prov_" ".labels.list.endpoint")
    local method_=$(get_api "$prov_" ".labels.list.method")
    call_api "$prov_" "$method_" "${endpoint_//:repo/$repo_}"
}

function edit_issue {
    local repo_="$1"
    local prov_="$2"

    local list_endpoint=$(get_api "$prov_" ".issues.list.endpoint")
    local list_method=$(get_api "$prov_" ".issues.list.method")
    local issues=$(call_api "$prov_" "$list_method" "${list_endpoint//:repo/$repo_}")

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

    local update_endpoint=$(get_api "$prov_" ".issues.update.endpoint")
    update_endpoint="${update_endpoint//:repo/$repo_}"
    update_endpoint="${update_endpoint//:issue_number/$number_}"
    local issue=$(call_api "$prov_" "GET" "$update_endpoint")

    if [[ $? -ne 0 || -z "$issue" || "$(echo "$issue" | jq -r '.message')" == "Not Found" ]]; then
        error_ "Could not fetch issue details."
        return 1
    fi

    local current_title=$(echo "$issue" | jq -r '.title // "No Title"')
    local current_body=$(echo "$issue" | jq -r '.body // "No description available."')
    local current_labels=$(echo "$issue" | jq -r '[.labels[]?.name] | join(", ") // "null"')
    local current_assignee=$(echo "$issue" | jq -r '.assignee?.login // ""')

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
    echo -e ${PRIMARY}Labels:${RESET} "$current_labels"
    primary_ "New Labels:"

    local labels=$(fetch_labels "$repo_" "$prov_")
    local label_names=$(echo "$labels" | jq -r '.[].name')
    local selected_labels=$(echo "$label_names" | fzf --multi $FZF_GEOMETRY)
    local selected_labels_json=$(echo "$selected_labels" | jq --raw-input --slurp 'split("\n") | map(select(length > 0))')  

    line_
    echo -e ${PRIMARY}Assignee:${RESET} "$current_assignee"
    primary_ -c "Assignee:" -n "(leave blank to unassign)"
    input_ -v new_assignee

    local json_assignee_value="null"
    if [[ -n "$new_assignee" ]]; then
        json_assignee_value="\"$new_assignee\""
    fi

    local data_=$(jq -n \
        --arg title "$new_title" \
        --arg body "$new_body" \
        --argjson labels "$selected_labels_json" \
        --argjson assignee "$json_assignee_value" \
        '{title: $title, body: $body, labels: $labels, assignee: $assignee}')

    local response=$(call_api "$prov_" "PATCH" "$update_endpoint" "$data_")

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
    local state_label="$4"

    local endpoint_=$(get_api "$prov_" ".issues.list.endpoint")
    local method_=$(get_api "$prov_" ".issues.list.method")
    local issues_=$(call_api "$prov_" "$method_" "${endpoint_//:repo/$repo_}?state=$state_label")

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

        local endpoint_=$(get_api "$prov_" ".issues.update.endpoint")
        local method_=$(get_api "$prov_" ".issues.update.method")
        endpoint_="${endpoint_/:repo/$repo_}"
        endpoint_="${endpoint_/:issue_number/$number_}"

        local data_="{\"state\": \"$state_new\"}"
        local response=$(call_api "$prov_" "$method_" "$endpoint_" "$data_")

        if response_ $response; then 
            done_ "The issue status has been changed."
        else
            error_ "Failed to change issue status."
            error_ "Response: $response"
        fi 
    done
}

function browse_issue() {
    local repo_="$1"
    local prov_="$2"
    local url=$(url_ "issue" "$prov_" "$repo_" )
    browser_ "$url"
}

function BROWSE_issue() {
    local repo_="$1"
    local prov_="$2"
    local issues=$(list_issues "$repo" "$provider")
    local selection_=$(echo "$issues" | fzf $FZF_GEOMETRY --inline-info)  
    if [[ -n "$selection_" ]]; then
        local url=$(url_ "issue" "$prov_" "$repo_" "$selection_" )
        browser_ "$url"
    else
        error_ "No issue selected."
    fi  
}


