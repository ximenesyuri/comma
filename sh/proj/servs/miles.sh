function miles_ {
    PROJ_DEPS
    local proj_="$1"
    local act_="$2"
    shift 2

    # if is_error_ $(proj_allow miles $proj_); then
    #     return 1
    # fi

    local repo_=$(proj_get repo $proj_)
    local prov_=$(proj_get prov $proj_)

    case "$act_" in
        l|ls|list)
            list_milestones "$repo_" "$prov_"
            ;;
        n|new)
            new_milestone "$repo_" "$prov_"
            ;;
        e|edit)
            edit_milestone "$repo_" "$prov_"
            ;;
        r|rm|remove|d|del|delete)
            remove_milestone "$repo_" "$prov_"
            ;;
        s|set)
            if [[ "$1" == "issue" ]]; then
                set_milestone "$repo_" "$prov_" "issues"
            elif [[ "$1" == "pr" || "$1" == "mr" ]]; then
                set_milestone "$repo_" "$prov_" "prs"
            else
                error_ "Invalid command, use 'set issue' or 'set pr/mr'."
                return 1
            fi
            ;;
        *)
            error_ "Milestone actions: 'ls', 'new', 'edit', 'rm', 'set'."
            return 1
            ;;
    esac
}

function list_milestones {
    local repo_="$1"
    local prov_="$2"

    local milestones_json=$(fetch_milestones "$repo_" "$prov_")
    if is_error_ "$milestones_json"; then
        return 1
    fi

    local selected=$(echo "$milestones_json" | jq -r '.[] | "\(.id) \(.title)"' | fzf $FZF_GEOMETRY)
    if [[ -n "$selected" ]]; then
        local milestone_id=$(echo "$selected" | awk '{print $1}')
        show_milestone "$repo_" "$prov_" "$milestone_id"
    else
        error_ "No milestone selected."
        return 1
    fi
}

function show_milestone {
    local repo_="$1"
    local prov_="$2"
    local milestone_id="$3"

    local endpoint=$(endpoint_ "milestone" "$prov_" "$repo_" "get" "$milestone_id")
    local method=$(method_ "milestones" "$prov_" "get")
    local response=$(call_api "$prov_" "$method" "$endpoint")

    if is_error_ "$response"; then
        return 1
    fi

    local title=$(echo "$response" | jq -r '.title // "No Title"')
    local description=$(echo "$response" | jq -r '.description // "No Description"')
    local due_date=$(echo "$response" | jq -r '.due_on // "No Due Date"')

    printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "Title:" "$title"
    printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "Description:" "$description"
    printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "Due Date:" "$due_date"
    line_
}

function new_milestone {
    local repo_="$1"
    local prov_="$2"

    primary_ "Title:"
    input_ -v title
    line_
    primary_ "Description:"
    input_ -e md -v description
    line_
    primary_ "Due (YYYY-MM-DD):"
    read -e -p "> " due_date

    local endpoint=$(endpoint_ "milestone" "$prov_" "$repo_" "create")
    local method=$(method_ "milestones" "$prov_" "create")
    local json_payload=$(payload_ "milestone" "$prov_" "create" title="$title" description="$description" due_date="$due_date")

    local response=$(call_api "$prov_" "$method" "$endpoint" "$json_payload")
    if response_ "$response"; then
        done_ "Milestone created successfully."
    else
        error_ "Failed to create milestone."
        echo "$response"
    fi
}

function edit_milestone {
    local repo_="$1"
    local prov_="$2"

    local milestones_json=$(fetch_milestones "$repo_" "$prov_")
    if is_error_ "$milestones_json"; then
        return 1
    fi

    local selected=$(echo "$milestones_json" | jq -r '.[] | "\(.id) \(.title)"' | fzf $FZF_GEOMETRY)
    local milestone_id=$(echo "$selected" | awk '{print $1}')
    if [[ -z "$milestone_id" ]]; then
        error_ "No milestone selected."
        return 1
    fi

    local current=$(echo "$milestones_json" | jq -r ".[] | select(.id == $milestone_id)")
    local current_title=$(echo "$current" | jq -r '.title')
    local current_description=$(echo "$current" | jq -r '.description')
    local current_due_date=$(echo "$current" | jq -r '.due_on')

    primary_ "New Title (current: $current_title):"
    input_ -v new_title
    new_title=${new_title:-$current_title}

    primary_ "New Description (current: $current_description):"
    input_ -e md -v new_description
    new_description=${new_description:-$current_description}

    primary_ "New Due Date (current: $current_due_date):"
    read -e -p "> " new_due_date
    new_due_date=${new_due_date:-$current_due_date}

    local endpoint=$(endpoint_ "milestone" "$prov_" "$repo_" "edit" "$milestone_id")
    local method=$(method_ "milestones" "$prov_" "edit")
    local json_payload=$(payload_ "milestone" "$prov_" "update" title="$new_title" description="$new_description" due_date="$new_due_date")

    local response=$(call_api "$prov_" "$method" "$endpoint" "$json_payload")
    if response_ "$response"; then
        done_ "Milestone updated successfully."
    else
        error_ "Failed to update milestone."
    fi
}

function remove_milestone {
    local repo_="$1"
    local prov_="$2"

    local milestones_json=$(fetch_milestones "$repo_" "$prov_")
    if is_error_ "$milestones_json"; then
        return 1
    fi

    local selected=$(echo "$milestones_json" | jq -r '.[] | "\(.id) \(.title)"' | fzf $FZF_GEOMETRY)
    local milestone_id=$(echo "$selected" | awk '{print $1}')
    if [[ -z "$milestone_id" ]]; then
        error_ "No milestone selected."
        return 1
    fi

    local endpoint=$(endpoint_ "milestone" "$prov_" "$repo_" "delete" "$milestone_id")
    local method=$(method_ "milestones" "$prov_" "delete")

    local response=$(call_api "$prov_" "$method" "$endpoint")
    if response_ "$response"; then
        done_ "Milestone '$milestone_id' has been removed."
    else
        error_ "Failed to remove milestone '$milestone_id'."
    fi
}

function set_milestone {
    local repo_="$1"
    local prov_="$2"
    local type="$3"

    local milestones_json=$(fetch_milestones "$repo_" "$prov_")
    if is_error_ "$milestones_json"; then
        return 1
    fi

    local selected=$(echo "$milestones_json" | jq -r '.[] | "\(.id) \(.title)"' | fzf $FZF_GEOMETRY)
    local milestone_id=$(echo "$selected" | awk '{print $1}')
    if [[ -z "$milestone_id" ]]; then
        error_ "No milestone selected."
        return 1
    fi

    local items_json=$(fetch_items "$repo_" "$prov_" "$type")
    if is_error_ "$items_json"; then
        return 1
    fi

    local selected_items=$(echo "$items_json" | jq -r '.[] | "\(.id) \(.title)"' | fzf --multi $FZF_GEOMETRY)
    if [[ -z "$selected_items" ]]; then
        error_ "No items selected."
        return 1
    fi

    echo "$selected_items" | while read -r item; do
        local item_id=$(echo "$item" | awk '{print $1}')
        update_item_milestone "$repo_" "$prov_" "$type" "$item_id" "$milestone_id"
    done
}

function fetch_milestones {
    local repo_="$1"
    local prov_="$2"
    local endpoint=$(endpoint_ "milestone" "$prov_" "$repo_" "list")
    local method=$(method_ "milestones" "$prov_" "list")
    call_api "$prov_" "$method" "$endpoint"
}

function fetch_items {
    local repo_="$1"
    local prov_="$2"
    local type="$3"

    local endpoint_method
    local endpoint
    case $type in
        issues)
            endpoint=$(endpoint_ "issue" "$prov_" "$repo_" "list")
            method=$(method_ "issues" "$prov_" "list")
            ;;
        prs)
            endpoint=$(endpoint_ "pr" "$prov_" "$repo_" "list")
            method=$(method_ "prs" "$prov_" "list")
            ;;
    esac

    call_api "$prov_" "$method" "$endpoint"
}

function update_item_milestone {
    local repo_="$1"
    local prov_="$2"
    local type="$3"
    local item_id="$4"
    local milestone_id="$5"

    local endpoint
    local method
    case $type in
        issues)
            endpoint=$(endpoint_ "issue" "$prov_" "$repo_" "update" "$item_id")
            method=$(method_ "issues" "$prov_" "update")
            ;;
        prs)
            endpoint=$(endpoint_ "pr" "$prov_" "$repo_" "update" "$item_id")
            method=$(method_ "prs" "$prov_" "update")
            ;;
    esac

    local json_payload=$(payload_ "$type" "$prov_" "update" milestone_id="$milestone_id")
    call_api "$prov_" "$method" "$endpoint" "$json_payload"
}

