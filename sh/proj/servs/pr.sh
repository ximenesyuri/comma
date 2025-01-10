function pr_ {
    local proj_="$1"
    local act="$2"
    shift 2

    if ! $(proj_allow pr $proj_);then
        error_ "Project '$proj_' does not allow pull-requests."
        return 1
    fi
    local repo_=$(proj_get repo $proj_)
    local prov_=$(proj_get prov $proj_)

    case "$act" in        
        l|ls|list)
            list_pr "$repo_" "$prov_"
            ;;
        n|new)
            create_pr "$repo_" "$prov_"
            ;;
        e|edit)
            edit_pr "$repo_" "$prov_"
            ;;
        a|approve)
            approve_pr "$repo_" "$prov_"
            ;;
        d|disapprove)
            disapprove_pr "$repo_" "$prov_"
            ;;
        c|close)
            close_pr "$repo_" "$prov_"
            ;;
        o|open)
            open_pr "$repo_" "$prov_"
            ;;
        *)
            error_ "PR actions: 'list', 'new', 'edit', 'approve', 'disapprove', 'close', 'open'."
            return 1
            ;;
    esac
}

function new_pr {
    local repo_="$1"
    local prov_="$2"

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

    local endpoint=$(pr_endpoint "$prov_" "new")
    local method=$(get_api "$prov_" ".prs.create.method")
    local json_payload="{\"title\": \"$title\", \"body\": $description, \"base\": \"$base\", \"head\": \"$head\"}"
    local response=$(call_api "$prov_" "$method" "${endpoint//:repo/$repo_}" "$json_payload")

    if response_ "$response"; then
        done_ "The pull request has been created."
    else
        error_ "Failed to create the pull request."
        error_ "Response: $response"
    fi
}

function edit_pr {
    local repo_="$1"
    local prov_="$2"

    local selections=$(list_prs "$repo_" "$prov_" "open")
    local number=$(echo "$selections" | fzf $FZF_GEOMETRY | awk '{print $1}')
    [ -z "$number" ] && { error_ "No PR selected."; return; }

    local endpoint=$(get_api "$prov_" ".prs.update.endpoint")
    local pr=$(call_api "$prov_" "GET" "${endpoint//:repo/$repo_}/${number}")
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
    local response=$(call_api "$prov_" "PATCH" "${endpoint//:repo/$repo_}/${number}" "$json_payload")

    if response_ "$response"; then
        done_ "The pull request has been updated."
    else
        error_ "Failed to update the pull request."
        error_ "Response: $response"
    fi
}


function approve_pr {
    local repo_="$1"
    local prov_="$2"
    local selections=$(list_pr "$repo_" "$prov_" "open")
    echo "$selections" | fzf --multi $FZF_GEOMETRY | awk '{print $1}' | while read -r number; do
        local endpoint=$(get_api "$prov_" ".prs.approve.endpoint")
        local method=$(get_api "$prov_" ".prs.approve.method")
        local response=$(call_api "$prov_" "$method" "${endpoint//:repo/$repo_}/${number}/approve")

        if response_ "$response"; then
            done_ "Pull request $number approved."
        else
            error_ "Failed to approve pull request $number."
        fi
    done
}

function disapprove_pr {
    local repo_="$1"
    local prov_="$2"
    local selections=$(list_pr "$repo_" "$prov_" "open")
    echo "$selections" | fzf --multi $FZF_GEOMETRY | awk '{print $1}' | while read -r number; do
        local endpoint=$(get_api "$prov_" ".prs.disapprove.endpoint")
        local method=$(get_api "$prov_" ".prs.disapprove.method")
        local response=$(call_api "$prov_" "$method" "${endpoint//:repo/$repo_}/${number}/disapprove")

        if response_ "$response"; then
            done_ "Pull request $number disapproved."
        else
            error_ "Failed to disapprove pull request $number."
        fi
    done
}

function close_pr {
    local repo_="$1"
    local prov_="$2"
    local selections=$(list_pr "$repo_" "$prov_" "open")
    echo "$selections" | fzf --multi $FZF_GEOMETRY | awk '{print $1}' | while read -r number; do
        local endpoint=$(get_api "$prov_" ".prs.update.endpoint")
        local json_payload="{\"state\": \"closed\"}"
        local response=$(call_api "$prov_" "PATCH" "${endpoint//:repo/$repo_}/${number}" "$json_payload")

        if response_ "$response"; then
            done_ "Pull request '$number' has been closed."
        else
            error_ "Failed to close pull request $number."
        fi
    done
}

function open_pr {
    local repo_="$1"
    local prov_="$2"
    local selections=$(list_pr "$repo_" "$prov_" "closed")
    echo "$selections" | fzf --multi $FZF_GEOMETRY | awk '{print $1}' | while read -r number; do
        local endpoint=$(get_api "$prov_" ".prs.update.endpoint")
        local json_payload="{\"state\": \"open\"}"
        local response=$(call_api "$prov_" "PATCH" "${endpoint//:repo/$repo_}/${number}" "$json_payload")

        if response_ "$response"; then
            done_ "Pull request $number opened."
        else
            error_ "Failed to open pull request $number."
        fi
    done
}

function list_pr {
    local repo_="$1"
    local prov_="$2"
    local state="${3:-open}"

    local endpoint=$(get_api "$prov_" ".prs.list.endpoint")
    local method=$(get_api "$prov_" ".prs.list.method")
    local prs=$(call_api "$prov_" "$method" "${endpoint//:repo/$repo_}?state=$state")

    if [[ $? -ne 0 || -z "$prs" ]]; then
        error_ "Could not fetch pull requests."
        exit 1
    fi

    echo "$prs" | jq -r '.[] | "\(.number) \(.title)"'
}

function BROWSE_pr() {
    local repo_="$1"
    local prov_="$2"
    local url=$(url_ "issue" "$prov_" "$repo_" )
    browser_ "$url"
}

function browse_pr() {
    local repo_="$1"
    local prov_="$2"
    local prs=$(list_pr "$repo_" "$prov_")
    local selection_=$(echo "$prs" | fzf $FZF_GEOMETRY --inline-info)
    local id_=$(echo "$selection_" | awk '{print $1}')
    if [[ -n "$id_" ]]; then
        local url=$(url_ "pr" "$prov_" "$repo_" "$id_")
        browser_ "$url"
    else
        error_ "No pr selected."
    fi
}

