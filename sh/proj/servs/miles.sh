function miles_ {
    local proj_="$1"
    local act_="$2"
    local proj_str=".projects.$proj_"
    shift 2

    if [[ $(yq e "$proj_str.spec.services.miles" $YML_PROJECTS) != "true" ]]; then
        error_ "Project '$proj_' does not support milestones."
        return 2
    fi

    local repo_=$(yq e "$proj_str.spec.repo"  $YML_PROJECTS)
    local prov_=$(yq e "$proj_str.spec.provider" $YML_PROJECTS)

    case "$act_" in
        l|ls|list)
            list_miles "$repo_" "$prov_"
            ;;
        n|new)
            new_miles "$repo_" "$prov_"
            ;;
        e|edit)
            edit_miles "$repo_" "$prov_"
            ;;
        r|rm|remove|d|del|delete)
            remove_miles "$repo_" "$prov_"
            ;;
        s|set)
            if [[ "$1" == "issue" ]]; then
                set_miles "$repo_" "$prov_" "issues"
            elif [[ "$1" == "pr" || "$1" == "mr" ]]; then
                set_miles "$repo_" "$prov_" "prs"
            else
                error_ "Invalid command, use 'set issue' or 'set pr/mr'."
                return 1
            fi
            ;;
        *)
            error_ "Milestones actions: 'ls', 'new', 'edit', 'rm', 'set'."
            return 1
            ;;
    esac
}

function list_miles {
    local repo_="$1"
    local prov_="$2"
    local milestones=$(fetch_miles "$repo_" "$prov_" | jq 'if length == 0 then empty else . end')
    if [[ -n "$milestones" ]]; then
        milestones=$( echo $milestones | jq -r '.[] | "\(.id) \(.title)"' | fzf $FZF_GEOMETRY)
    else
        error_ "There are no milestones in repo '$repo_'."
        return 1
    fi
    if [[ -n "$milestones" ]]; then
        local milestone_id=$(echo "$milestones" | awk '{print $1}')
        show_miles "$repo_" "$prov_" "$milestone_id"
    else
        error_ "No milestone selected."
        return 1
    fi
}

function new_miles {
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

    local due_date_formatted="$(date_ $due_date)"

    local endpoint_=$(get_api "$prov_" ".milestones.create.endpoint")
    local method_=$(get_api "$prov_" ".milestones.create.method")
    local json_payload="{\"title\": \"$title\", \"description\": \"$description\", \"due_on\": \"$due_date_formatted\"}"
    local response=$(call_api "$prov_" "$method_" "${endpoint_//:repo/$repo_}" "$json_payload")
    if response_ $response; then
        done_ "Milestone created successfully."
    else
        error_ "Failed to create milestone."
    fi
}

function edit_miles {
    local repo_="$1"
    local prov_="$2"
    local milestones=$(fetch_miles "$repo_" "$prov_" | jq 'if length == 0 then empty else . end')
    if [[ -n "$milestones" ]]; then
        local milestones=$( echo $milestones | jq -r '.[] | "\(.number) \(.title)"' | fzf $FZF_GEOMETRY)
    else
        error_ "There are no milestones in repo '$repo_'."
        return 1
    fi
    if [[ -n "$milestones" ]]; then
        local milestone_id=$(echo "$milestones" | awk '{print $1}')
        local current_miles=$(fetch_miles "$repo_" "$prov_" | jq -r ".[] | select(.id == $milestone_id)")
        local current_title=$(echo "$current_miles" | jq -r '.title')
        local current_description=$(echo "$current_miles" | jq -r '.description')
        local current_due_date=$(echo "$current_miles" | jq -r '.due_on')

        primary_ -c "Title:" -n "$current_title"
        primary_ "New Title:"
        input_ -v new_title
        line_
        primary_ -c "Description:" -n "$current_description"
        primary_ "New Description:"
        input_ -e md -v new_description
        line_
        primary_ -c "Due:" -n "$current_due_date"
        primary_ -c "New Due:" -n "(yyyy-mm-dd)"
        read -e -p "> " new_due_date

        local endpoint_=$(get_api "$prov_" ".milestones.update.endpoint")
        endpoint_="${endpoint_//:repo/$repo_}"
        endpoint_="${endpoint_/:milestone_id/$milestone_id}"
        local method_=$(get_api "$prov_" ".milestones.update.method")
        local json_payload="{\"title\": \"${new_title:-null}\", \"description\": \"${new_description:-null}\", \"due_on\": \"${new_due_date:-null}\"}"

        local response=$(call_api "$prov_" "$method_" "$endpoint_" "$json_payload")
        if response_ $response; then
            done_ "Milestone updated successfully."
            return 0
        else
            error_ "Failed to update milestone."
            return 1
        fi
    else
        error_ "No milestone selected."
        return 1
    fi
}

function remove_miles {
    local repo_="$1"
    local prov_="$2"
    local milestones=$(fetch_miles "$repo_" "$prov_" | jq 'if length == 0 then empty else . end')
    if [[ -n "$milestones" ]]; then
        milestones=$(echo $milestones| jq -r '.[] | "\(.number) \(.title)"' | fzf $FZF_GEOMETRY)
    else
        error_ "There are no milestones in repo '$repo_'."
        return 1
    fi

    if [[ -n "$milestones" ]]; then
        local milestone_number=$(echo "$milestones" | awk '{print $1}')
        local endpoint_=$(get_api "$prov_" ".milestones.delete.endpoint")
        endpoint_="${endpoint_//:repo/$repo_}"
        endpoint_="${endpoint_/:milestone_number/$milestone_number}"
        local method_=$(get_api "$prov_" ".milestones.delete.method")
        local response=$(call_api "$prov_" "$method_" "$endpoint_")

        if response_ $response; then
            done_ "Milestone '$milestone_number' has been removed."
            return 0
        else
            error_ "Failed to remove milestone '$milestone_number'."
            error_ "Response: $response"
            return 1
        fi
    else
        error_ "No milestone selected."
        return 1
    fi
}

function set_miles {
    local repo_="$1"
    local prov_="$2"
    local type="$3"
    local milestones=$(fetch_miles "$repo_" "$prov_" | jq 'if length == 0 then empty else . end')
    if [[ -n "$milestones" ]]; then
        local milestones=$(fetch_miles "$repo_" "$prov_" | jq -r '.[] | "\(.id) \(.title)"' | fzf $FZF_GEOMETRY)
    else
        error_ "There are no milestones in repo '$repo_'."
        return 1
    fi
    if [[ -n "$milestones" ]]; then
        local milestone_id=$(echo "$milestones" | awk '{print $1}')
        local items=$(fetch_items "$repo_" "$prov_" "$type" | jq -r '.[] | "\(.id) \(.title)"' | fzf --multi $FZF_GEOMETRY)
        if [[ -n "$items" ]]; then
            echo "$items" | while read -r item; do
                local item_id=$(echo "$item" | awk '{print $1}')
                update_item_miles "$repo_" "$prov_" "$type" "$item_id" "$milestone_id"
            done
            done_ "Milestone set for selected items."
            return 0
        else
            error_ "No items selected."
            return 1
        fi
    else
        error_ "No milestone selected."
        return 1
    fi
}

function fetch_miles {
    local repo_="$1"
    local prov_="$2"
    local endpoint_=$(get_api "$prov_" ".milestones.list.endpoint")
    local method_=$(get_api "$prov_" ".milestones.list.method")
    call_api "$prov_" "$method_" "${endpoint_//:repo/$repo_}"
}

function fetch_items {
    local repo_="$1"
    local prov_="$2"
    local type="$3"
    local endpoint_
    local method_

    case $type in
        issues)
            endpoint_=$(get_api "$prov_" ".issues.list.endpoint")
            method_=$(get_api "$prov_" ".issues.list.method")
            ;;
        prs)
            endpoint_=$(get_api "$prov_" ".prs.list.endpoint")
            method_=$(get_api "$prov_" ".prs.list.method")
            ;;
    esac

    call_api "$prov_" "$method_" "${endpoint_//:repo/$repo_}"
}

function update_item_miles {
    local repo_="$1"
    local prov_="$2"
    local type="$3"
    local item_id="$4"
    local milestone_id="$5"
    local endpoint_
    local method_

    case $type in
        issues)
            endpoint_=$(get_api "$prov_" ".issues.update.endpoint")
            method_=$(get_api "$prov_" ".issues.update.method")
            ;;
        prs)
            endpoint_=$(get_api "$prov_" ".prs.update.endpoint")
            method_=$(get_api "$prov_" ".prs.update.method")
            ;;
    esac

    endpoint_="${endpoint_//:repo/$repo_}"
    endpoint_="${endpoint_/:item_id/$item_id}"
    local json_payload="{\"milestone_id\": \"$milestone_id\"}"

    call_api "$prov_" "$method_" "$endpoint_" "$json_payload"
}

