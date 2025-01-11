function comments_ {
    local repo_="$1"
    local prov_="$2"
    shift 2
    local action="$1"
 
    case "$action" in
        ls) list_comments "$repo_" "$prov_" ;;
        new|n) new_comment "$repo_" "$prov_" ;;
        edit|e) edit_comments "$repo_" "$prov_" ;;
        rm|r) delete_comments "$repo_" "$prov_" ;;
        *)
            error_ "Available comment actions: 'ls', 'new', 'edit', 'rm'."
            return 1
            ;;
    esac
}

function select_issue {
    local repo_="$1"
    local prov_="$2"

    local endpoint=$(endpoint_ "issue" "$prov_" "$repo_" "list")
    local method=$(method_ "issues" "$prov_" "list")
    local issues=$(call_api "$prov_" "$method" "$endpoint")

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

    local endpoint=$(endpoint_ "comment" "$prov_" "$repo_" "list" "$issue_number")
    local method=$(method_ "issues" "$prov_" "comments")

    local response=$(call_api "$prov_" "$method" "$endpoint")

    if echo "$response" | jq empty 2>/dev/null; then
        echo "$response"
    else
        error_ "Failed to fetch comments or invalid response. Response: $response"
        return 1
    fi
}

function list_comments {
    local repo_="$1"
    local prov_="$2"

    local issue_number=$(select_issue "$repo_" "$prov_")
    if [[ -n "$issue_number" ]]; then
        local comments_json=$(fetch_issue_comments "$repo_" "$prov_" "$issue_number")
        if [[ -n "$(echo "$comments_json" | grep error:)" ]]; then
            echo "$comments_json"
            return 1
        fi

        if echo "$comments_json" | jq -e . >/dev/null 2>&1; then
            local comment_ids=$(select_comment "$comments_json" --multi)
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
}

function new_comment {
    local repo_="$1"
    local prov_="$2"

    local issue_number=$(select_issue "$repo_" "$prov_")
    if [[ -n "$issue_number" ]]; then
        primary_ "Comment Body:"
        input_ -e "md" -v comment_body

        local endpoint=$(endpoint_ "comment" "$prov_" "$repo_" "create" "$issue_number")
        local method=$(method_ "issues" "$prov_" "create")
        local json_payload="{\"body\": \"$comment_body\"}"

        call_api "$prov_" "$method" "$endpoint" "$json_payload" && done_ "Comment added successfully."
    else
        error_ "No issue selected."
    fi
}

function edit_comments {
    local repo_="$1"
    local prov_="$2"

    local issue_number=$(select_issue "$repo_" "$prov_")
    if [[ -n "$issue_number" ]]; then
        local comments_json=$(fetch_issue_comments "$repo_" "$prov_" "$issue_number")

        if [[ -n "$(echo "$comments_json" | grep error:)" ]]; then
            echo "$comments_json"
            return 1
        fi

        local comment_ids=$(select_comment "$comments_json" --multi)
        if [[ -n "$comment_ids" ]]; then
            echo "$comment_ids" | while read -r comment_id; do
                primary_ "New content for comment #$comment_id:"
                read -e -r -p "> " new_comment_body

                if [[ -z "$new_comment_body" ]]; then
                    error_ "Comment body cannot be blank."
                    continue
                fi

                local endpoint=$(endpoint_ "comment" "$prov_" "$repo_" "edit" "$comment_id")
                local method=$(method_ "issues" "$prov_" "edit")
                local json_payload="{\"body\": \"$new_comment_body\"}"

                local response=$(call_api "$prov_" "$method" "$endpoint" "$json_payload")

                if [[ "$(echo "$response" | jq -r '.message')" == "Not Found" ]]; then
                    error_ "Failed to edit comment #$comment_id. The comment might not exist or check permissions."
                else
                    done_ "Comment #$comment_id edited successfully."
                fi
            done
        else
            error_ "No comments selected for editing."
        fi
    else
        error_ "No issue selected."
    fi
}

function delete_comments {
    local repo_="$1"
    local prov_="$2"

    local issue_number=$(select_issue "$repo_" "$prov_")
    if [[ -n "$issue_number" ]]; then
        local comments_json=$(fetch_issue_comments "$repo_" "$prov_" "$issue_number")

        if [[ -n "$(echo "$comments_json" | grep error:)" ]]; then
            return 1
        fi

        local selected_comments=$(select_comment "$comments_json" --multi)
        if [[ -n "$selected_comments" ]]; then
            echo "Delete the comments? (y/n)"
            read -e -r -p "> " confirm
            if [[ "$confirm" == "y" ]]; then
                echo "$selected_comments" | while read -r comment_id; do
                    local endpoint=$(endpoint_ "comment" "$prov_" "$repo_" "delete" "$comment_id")
                    local method=$(method_ "issues" "$prov_" "delete")

                    local response=$(call_api "$prov_" "$method" "$endpoint")

                    if echo "$response" | jq -e '.message == "Not Found"' > /dev/null 2>&1; then
                        error_ "Failed to delete comment #$comment_id. The comment might not exist or check permissions."
                    else
                        done_ "Comment #$comment_id deleted successfully."
                    fi
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
}

function select_comment {
    local comments_json="$1"
    local options="$2"

    echo "$comments_json" | jq -r '.[] | if .body then (.id | tostring) + " " + .user.login + " " + (if (.body | gsub("\n"; " ") | length) > 80 then (.body | gsub("\n"; " ") | .[0:80] + "...") else .body | gsub("\n"; " ") end) else (.id | tostring) + " " + .user.login + " " + "Empty comment" end' | fzf $options $FZF_GEOMETRY | awk '{print $1}'
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

