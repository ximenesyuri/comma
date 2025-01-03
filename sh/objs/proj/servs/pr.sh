function pr_ {
    local proj="$1"
    local act="$2"
    shift 2

    local repo=$(yq e ".projects.$proj.server.spec.repo" "$YML_PROJECTS")
    local provider=$(yq e ".projects.$proj.server.spec.provider" "$YML_PROJECTS")

    case "$act" in        
        l|ls|list)
            list_pr "$repo" "$provider"
            ;;
        n|new)
            create_pr "$repo" "$provider"
            ;;
        e|edit)
            edit_pr "$repo" "$provider"
            ;;
        a|approve)
            approve_pr "$repo" "$provider"
            ;;
        d|disapprove)
            disapprove_pr "$repo" "$provider"
            ;;
        c|close)
            close_pr "$repo" "$provider"
            ;;
        o|open)
            open_pr "$repo" "$provider"
            ;;
        *)
            error_ "PR actions: 'list', 'new', 'edit', 'approve', 'disapprove', 'close', 'open'."
            return 1
            ;;
    esac
}

function new_pr {
    local repo="$1"
    local provider="$2"

    primary_ "Title:"
    input_ -v title
    line_
    primary_ "Description:"
    input_ -e md -v description
    line_
    primary_ "Source Branch:"
    input_ -v base
    line_
    primary_ "Target Branch:"
    input_ -v head
    line_

    local endpoint=$(pr_endpoint "$provider" "new")
    local method=$(get_api "$provider" ".prs.create.method")
    local json_payload="{\"title\": \"$title\", \"body\": $description, \"base\": \"$base\", \"head\": \"$head\"}"
    local response=$(call_api "$provider" "$method" "${endpoint//:repo/$repo}" "$json_payload")

    if response_ "$response"; then
        done_ "The pull request has been created."
    else
        error_ "Failed to create the pull request."
        error_ "Response: $response"
    fi
}

function edit_pr {
    local repo="$1"
    local provider="$2"

    local selections=$(list_prs "$repo" "$provider" "open")
    local number=$(echo "$selections" | fzf $FZF_GEOMETRY | awk '{print $1}')
    [ -z "$number" ] && { error_ "No PR selected."; return; }

    local endpoint=$(get_api "$provider" ".prs.update.endpoint")
    local pr=$(call_api "$provider" "GET" "${endpoint//:repo/$repo}/${number}")
    local title=$(echo "$pr" | jq -r '.title')
    local body=$(echo "$pr" | jq -r '.body')

    primary_ -c "Current Title:" -n "$title"
    input_ -v new_title
    new_title="${new_title:-$title}"
    line_
    primary_ -c "Current Description:" -n "$body"
    input_ -e md -v new_body
    new_body="${new_body:-$body}"

    local json_payload="{\"title\": \"$new_title\", \"body\": $new_body}"
    local response=$(call_api "$provider" "PATCH" "${endpoint//:repo/$repo}/${number}" "$json_payload")

    if response_ "$response"; then
        done_ "The pull request has been updated."
    else
        error_ "Failed to update the pull request."
        error_ "Response: $response"
    fi
}


function approve_pr {
    local repo="$1"
    local provider="$2"
    local selections=$(list_prs "$repo" "$provider" "open")
    echo "$selections" | fzf --multi $FZF_GEOMETRY | awk '{print $1}' | while read -r number; do
        local endpoint=$(get_api "$provider" ".prs.approve.endpoint")
        local method=$(get_api "$provider" ".prs.approve.method")
        local response=$(call_api "$provider" "$method" "${endpoint//:repo/$repo}/${number}/approve")

        if response_ "$response"; then
            done_ "Pull request $number approved."
        else
            error_ "Failed to approve pull request $number."
        fi
    done
}

function disapprove_pr {
    local repo="$1"
    local provider="$2"
    local selections=$(list_prs "$repo" "$provider" "open")
    echo "$selections" | fzf --multi $FZF_GEOMETRY | awk '{print $1}' | while read -r number; do
        local endpoint=$(get_api "$provider" ".prs.disapprove.endpoint")
        local method=$(get_api "$provider" ".prs.disapprove.method")
        local response=$(call_api "$provider" "$method" "${endpoint//:repo/$repo}/${number}/disapprove")

        if response_ "$response"; then
            done_ "Pull request $number disapproved."
        else
            error_ "Failed to disapprove pull request $number."
        fi
    done
}

function close_pr {
    local repo="$1"
    local provider="$2"
    local selections=$(list_prs "$repo" "$provider" "open")
    echo "$selections" | fzf --multi $FZF_GEOMETRY | awk '{print $1}' | while read -r number; do
        local endpoint=$(get_api "$provider" ".prs.update.endpoint")
        local json_payload="{\"state\": \"closed\"}"
        local response=$(call_api "$provider" "PATCH" "${endpoint//:repo/$repo}/${number}" "$json_payload")

        if response_ "$response"; then
            done_ "Pull request $number closed."
        else
            error_ "Failed to close pull request $number."
        fi
    done
}

function open_pr {
    local repo="$1"
    local provider="$2"
    local selections=$(list_prs "$repo" "$provider" "closed")
    echo "$selections" | fzf --multi $FZF_GEOMETRY | awk '{print $1}' | while read -r number; do
        local endpoint=$(get_api "$provider" ".prs.update.endpoint")
        local json_payload="{\"state\": \"open\"}"
        local response=$(call_api "$provider" "PATCH" "${endpoint//:repo/$repo}/${number}" "$json_payload")

        if response_ "$response"; then
            done_ "Pull request $number opened."
        else
            error_ "Failed to open pull request $number."
        fi
    done
}

function list_pr {
    local repo="$1"
    local provider="$2"
    local state="${3:-open}"

    local endpoint=$(get_api "$provider" ".prs.list.endpoint")
    local method=$(get_api "$provider" ".prs.list.method")
    local prs=$(call_api "$provider" "$method" "${endpoint//:repo/$repo}?state=$state")

    if [[ $? -ne 0 || -z "$prs" ]]; then
        error_ "Could not fetch pull requests."
        exit 1
    fi

    echo "$prs" | jq -r '.[] | "\(.number) \(.title)"'
}
