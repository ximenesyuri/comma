function comments_ {
    local proj_="$1"
    shift
    local action="$2"

    if ! $(proj_allow comment $proj_);then
        error_ "Project '$proj_' does not allow comments."
        return 1
    fi

    local repo_=$(proj_get repo $proj_)
    local prov_=$(proj_get prov $proj_)

    case "$action" in
        ls)
            local issue_number=$(select_issue "$repo_" "$prov_")
            if [[ -n "$issue_number" ]]; then
                local comments_json=$(check_for_comments "$repo_" "$prov_" "$issue_number")
                if [[ -n "$(echo $comments_json | grep error:)" ]]; then
                    echo $comments_json
                    return 1
                fi
                if echo "$comments_json" | jq -e . >/dev/null 2>&1; then
                    local comment_ids=$(select_comment "$repo_" "$prov_" "$issue_number" --multi)
                    if [[ -n "$comment_ids" ]]; then
                        echo "$comment_ids" | while read -r comment_id; do
                            if jq -e ".[] | select(.id == $comment_id)" <<< "$comments_json" > /dev/null 2>&1; then
                                local comment_json=$(echo "$comments_json" | jq -r ".[] | select(.id == $comment_id)")
                                display_comment "$comment_json"
                            else
                                error_ "Error processing comment #$comment_id."
                            fi
                        done
                    else
                        error_ "No comments selected."
                    fi
                else
                    error_ "Comments JSON is invalid or empty!"
                fi
            else
                error_ "No issue selected."
            fi
            ;; 
        new|n)
            primary_  "Select the issue:"
            local issue_number=$(select_issue "$repo_" "$prov_")
            if [[ -n "$issue_number" ]]; then
                add_comment "$repo_" "$prov_" "$issue_number"
            else
                error_ "No issue selected."
            fi
            ;;
        edit|e)
            primary_  "Select the issue:"
            local issue_number=$(select_issue "$repo_" "$prov_")
            if [[ -n "$issue_number" ]]; then
                local comments_json=$(check_for_comments "$repo_" "$prov_" "$issue_number")
                if [[ -n "$(echo $comments_json | grep error:)" ]]; then
                    echo $comments_json
                    return 1
                fi
                primary_  "Select the comments:"
                local comment_ids=$(select_comment "$repo_" "$prov_" "$issue_number" --multi)
                if [[ -n "$comment_ids" ]]; then
                    echo "$comment_ids" | while read -r comment_id; do
                        edit_comment "$repo_" "$prov_" "$issue_number" "$comment_id"
                    done
                else
                    error_ "No comments selected for editing."
                fi
            else
                error_ "No issue selected."
            fi
            ;;
        rm|r)
            primary_  "Select the issue:"
            local issue_number=$(select_issue "$repo_" "$prov_")
            if [[ -n "$issue_number" ]]; then
                local comments_json=$(check_for_comments "$repo_" "$prov_" "$issue_number")
                if [[ -n "$(echo $comments_json | grep error:)" ]]; then
                    return 1
                fi
                primary_  "Select the comments:"
                local selected_comments=$(select_comment "$repo_" "$prov_" "$issue_number" --multi)
                if [[ -n "$selected_comments" ]]; then
                    echo "Delete the comments? (y/n)"
                    read -e -r -p "> " confirm
                    if [[ "$confirm" == "y" ]]; then
                        echo "$selected_comments" | while read -r comment_id; do
                            delete_comments "$repo_" "$prov_" "$issue_number" "$comment_id"
                        done
                    else
                        echo "Comment deletion canceled."
                    fi
                else
                    error_ "No comments selected for deletion."
                fi
            else
                error_ "No issue selected."
            fi
            ;;
        *)
            error_ "Available comment actions: 'ls', 'new', 'edit', 'rm'."
            return 1
            ;;
    esac
}

function select_issue {
    local repo_="$1"
    local prov_="$2"
    local endpoint_list=$(get_api "$prov_" "issues.list.endpoint")
    issues=$(call_api "$prov_" "GET" "${endpoint_list//:repo/$repo_}")

    if [[ $? -ne 0 || -z "$issues" ]]; then
        error_ "Could not fetch issues."
        return 1
    fi

    local selection=$(echo "$issues" | jq -r '.[] | "\(.number) \(.title)"' | fzf $FZF_GEOMETRY)
    echo "$selection" | awk '{print $1}'
}

function fetch_issue_comments {
    local repo_="$1"
    local prov_="$2"
    local issue_number="$3"

    local endpoint_comments=$(get_api "$prov_" "issues.comment.list.endpoint")
    endpoint_comments="${endpoint_comments//:repo/$repo_}"
    endpoint_comments="${endpoint_comments//:issue_number/$issue_number}"

    local response=$(call_api "$prov_" "GET" "$endpoint_comments")

    if echo "$response" | jq empty 2>/dev/null; then
        echo "$response"
    else
        error_ "Failed to fetch comments or invalid response. Response: $response"
        return 1
    fi
}

function check_for_comments {
    local repo_="$1"
    local prov_="$2"
    local issue_number="$3"

    local comments_json=$(fetch_issue_comments "$repo_" "$prov_" "$issue_number")

    if [[ -z "$comments_json" || "$(echo "$comments_json" | jq -e 'length > 0' 2>/dev/null)" != "true" ]]; then
        error_ "No comments found for the issue."
        return 1
    fi

    echo "$comments_json"
    return 0
}

function add_comment {
    local repo_="$1"
    local prov_="$2"
    local issue_number="$3"

    primary_ "Comment Body:"
    input_ -e "md" -v comment_body

    local endpoint_comment=$(get_api "$prov_" "issues.comment.new.endpoint")
    endpoint_comment="${endpoint_comment//:repo/$repo_}"
    endpoint_comment="${endpoint_comment/:issue_number/$issue_number}"

    local json_payload="{\"body\": ${comment_body}}"

    call_api "$prov_" "POST" "$endpoint_comment" "$json_payload"
}

function select_comment {
    local repo_="$1"
    local prov_="$2"
    local issue_number="$3"
    local options="$4" 

    local selection=$(echo "$comments_json" | jq -r '.[] | if .body then (.id | tostring) + " " + .user.login + " " + (if (.body | gsub("\n"; " ") | length) > 80 then (.body | gsub("\n"; " ") | .[0:80] + "...") else .body | gsub("\n"; " ") end) else (.id | tostring) + " " + .user.login + " " + "Empty comment" end' | fzf $options $FZF_GEOMETRY)

    if [[ -n "$selection" ]]; then
        echo "$selection" | awk '{print $1}'
    else
        return 1
    fi
}

function display_comment {
    local comment_json="$1"

    local id=$(echo "$comment_json" | jq -r '.id // "Unknown"')
    local author=$(echo "$comment_json" | jq -r '.user.login // "Unknown"')
    local created_at=$(echo "$comment_json" | jq -r '.created_at // "Unknown"')
    local updated_at=$(echo "$comment_json" | jq -r '.updated_at // "Unknown"')
    local body=$(echo "$comment_json" | jq -r '.body // "No content." | @text' | fold_ | sed 's/^/    > /')

    printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "ID:" "$id"
    printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "author:" "$author"
    printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "creation:" "$created_at"
    printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "modif:" "$updated_at"
    line_
    printf "${PRIMARY}%-*s${RESET}\n" $LABEL_WIDTH "Contents:"
    echo -e "$body"
    line_
}


function edit_comment {
    local repo_="$1"
    local prov_="$2"
    local issue_number="$3" 
    local comment_id="$4"

    primary_ "New content:"
    read -e -r -p "> " new_comment_body

    if [[ -z "$new_comment_body" ]]; then
        error_ "Comment body cannot be blank."
        return 1
    fi

    local endpoint_comment=$(get_api "$prov_" "issues.comment.edit.endpoint")
    endpoint_comment="${endpoint_comment//:repo/$repo_}"
    endpoint_comment="${endpoint_comment//:comment_id/$comment_id}"

    local json_payload="{\"body\": \"${new_comment_body}\"}"

    local response=$(call_api "$prov_" "PATCH" "$endpoint_comment" "$json_payload")

    if [[ "$(echo "$response" | jq -r '.message')" == "Not Found" ]]; then
        error_ "Failed to edit comment #$comment_id. The comment might not exist or check permissions."
    else
        done_ "Comment #$comment_id edited successfully."
    fi
}

function delete_comments {
    local repo_="$1"
    local prov_="$2"
    local issue_number="$3"
    local comment_id="$4"

    local endpoint_comment=$(get_api "$prov_" "issues.comment.delete.endpoint")
    endpoint_comment="${endpoint_comment//:repo/$repo_}"
    endpoint_comment="${endpoint_comment//:comment_id/$comment_id}"

    local response=$(call_api "$prov_" "DELETE" "$endpoint_comment")

    if echo "$response" | jq -e '.message == "Not Found"' > /dev/null 2>&1; then
        error_ "Failed to delete comment #$comment_id. The comment might not exist or check permissions."
    else
        done_ "Comment #$comment_id deleted successfully."
    fi
}
