function web_issue() {
    local repo_="$1"
    local prov_="$2"
    local url=$(url_ "issue" "$prov_" "$repo_")
    browser_ "$url"
}

function WEB_issue() {
    local repo_="$1"
    local prov_="$2"
    local issues=$(list_issues "$repo_" "$prov_")
    local selection_=$(echo "$issues" | fzf $FZF_GEOMETRY --inline-info)
    if [[ -n "$selection_" ]]; then
        local url=$(url_ "issue" "$prov_" "$repo_" "$selection_")
        browser_ "$url"
    else
        error_ "No issue selected."
    fi
}

