function miles_ {
    local proj_="$1"
    local act_="$2"
    shift 2

    case "$act_" in
        ls)
            list_milestones "$proj_"
            ;;
        new)
            new_milestone "$proj_"
            ;;
        edit)
            edit_milestone "$proj_"
            ;;
        rm)
            remove_milestone "$proj_"
            ;;
        set)
            if [[ "$1" == "issue" ]]; then
                set_milestone "$proj_" "issues"
            elif [[ "$1" == "pr" || "$1" == "mr" ]]; then
                set_milestone "$proj_" "prs"
            else
                error_ "Invalid command, use 'set issue' or 'set pr/mr'."
                return 1
            fi
            ;;
        *)
            error_ "Available actions: 'ls', 'new', 'edit', 'rm', 'set'."
            return 1
            ;;
    esac
}

function show_milestone {
    local proj_="$1"
    local milestone_id="$2"
    
    local milestone=$(fetch_milestones "$proj_" | jq -r ".[] | select(.id == $milestone_id)")

    if [ -z "$milestone" ]; then
        error_ "Error fetching the milestone details."
        return 1
    fi
    
    local title=$(echo "$milestone" | jq -r '.title')
    local description=$(echo "$milestone" | jq -r '.description')
    local due_date=$(echo "$milestone" | jq -r '.due_on')
    local creation_date=$(echo "$milestone" | jq -r '.created_at')
    local modification_date=$(echo "$milestone" | jq -r '.updated_at')
    local author=$(echo "$milestone" | jq -r '.creator.login')

    if [ "$title" = "null" ] || [ "$title" = "" ]; then
        title="(No title found)"
    fi
    if [ "$description" = "null" ] || [ "$description" = "" ]; then
        description="(No description found)"
    fi
    if [ "$due_date" = "null" ] || [ "$due_date" = "" ]; then
        due_date="(No due date found)"
    fi

    local issues_array=($(fetch_items "$proj_" "issues" | jq -r ".[] | select(.milestone_id == $milestone_id) | .title"))
    local prs_array=($(fetch_items "$proj_" "prs" | jq -r ".[] | select(.milestone_id == $milestone_id) | .title"))

    entry_ "title" "$title"
    entry_ "desc" "$description"
    entry_ "due" "$due_date"
    line_
    entry_ "created" "$creation_date"
    entry_ "modif" "$modification_date"
    entry_ "author" "$author"
    line_
    entry_ "issues" " "
    list_ "${issues_array[@]}"
    entry_ "prs/mrs" " "
    list_ "${prs_array[@]}"
}

function list_milestones {
    local proj_="$1"
    local milestones=$(fetch_milestones "$proj_")
    local milestones=$( echo $milestones | jq -r '.[] | "\(.id) \(.title)"' | fzf $FZF_GEOMETRY)
    if [[ -n "$milestones" ]]; then
        local milestone_id=$(echo "$milestones" | awk '{print $1}')
        show_milestone "$proj_" "$milestone_id"
    else
        error_ "No milestone selected."
    fi
}

function new_milestone {
    local proj_="$1"
    primary_ "Title:"
    input_ -v title
    line_
    primary_ "Description:"
    input_ -e md -v description
    line_
    primary_ "Due (YYYY-MM-DD):"
    read -e -p "> " due_date
 
    local due_date="$(date_ $due_date)"

    local repo_=$(yq e ".projects.$proj_.server.spec.repo" $YML_PROJECTS)
    local prov_=$(yq e ".projects.$proj_.server.spec.provider" $YML_PROJECTS)
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

function edit_milestone {
    local proj_="$1"
    local milestones=$(fetch_milestones "$proj_" | jq -r '.[] | "\(.id) \(.title)"' | fzf $FZF_GEOMETRY)
    if [[ -n "$milestones" ]]; then
        local milestone_id=$(echo "$milestones" | awk '{print $1}')
        local current_milestone=$(fetch_milestones "$proj_" | jq -r ".[] | select(.id == $milestone_id)")
        local current_title=$(echo "$current_milestone" | jq -r '.title')
        local current_description=$(echo "$current_milestone" | jq -r '.description')
        local current_due_date=$(echo "$current_milestone" | jq -r '.due_on')

        primary_ -c "Title:" -n "$current_title"
        primary_ "New Title:"
        input_ -v new_title
        line_
        primary_ -c "Description:" -n "$current_description"
        primary_ "New Description:"
        input_ -e md -v new_description
        line_
        primary_ -c "Due:" -n "$current_due_date"
        primary_ -c "New Due:" -n "(yyy-mm-dd)"
        read -e -p "> " new_due_date

        local repo_=$(yq e ".projects.$proj_.server.spec.repo" $YML_PROJECTS)
        local prov_=$(yq e ".projects.$proj_.server.spec.provider" $YML_PROJECTS)
        local endpoint_=$(get_api "$prov_" ".milestones.update.endpoint")
        endpoint_="${endpoint_//:repo/$repo_}"
        endpoint_="${endpoint_/:milestone_id/$milestone_id}"
        local method_=$(get_api "$prov_" ".milestones.update.method")
        local json_payload="{\"title\": \"${new_title:-null}\", \"description\": \"${new_description:-null}\", \"due_on\": \"${new_due_date:-null}\"}"

        local response=$(call_api "$prov_" "$method_" "$endpoint_" "$json_payload")
        if response_ $response; then
            done_ "Milestone updated successfully."
        else
            error_ "Failed to update milestone."
        fi
    else
        error_ "No milestone selected."
    fi
}

function remove_milestone {
    local proj_="$1"

    local milestones=$(fetch_milestones "$proj_")
    milestones=$(echo $milestones| jq -r '.[] | "\(.number) \(.title)"' | fzf)
    
    if [[ -n "$milestones" ]]; then
        local milestone_number=$(echo "$milestones" | awk '{print $1}')
        local repo_=$(yq e ".projects.$proj_.server.spec.repo" $YML_PROJECTS)
        local prov_=$(yq e ".projects.$proj_.server.spec.provider" $YML_PROJECTS)
        local endpoint_=$(get_api "$prov_" ".milestones.delete.endpoint")

        endpoint_="${endpoint_//:repo/$repo_}"
        endpoint_="${endpoint_/:milestone_number/$milestone_number}"
        
        local method_=$(get_api "$prov_" ".milestones.delete.method")
        local response=$(call_api "$prov_" "$method_" "$endpoint_")
        
        if response_ $response; then
            done_ "Milestone '$milestone_number' has been removed."
        else
            error_ "Failed to remove milestone '$milestone_number'."
            error_ "Response: $response"
        fi 
    else
        error_ "No milestone selected."
    fi
}

function set_milestone {
    local proj_="$1"
    local type="$2"
    local milestones=$(fetch_milestones "$proj_" | jq -r '.[] | "\(.id) \(.title)"' | fzf)
    if [[ -n "$milestones" ]]; then
        local milestone_id=$(echo "$milestones" | awk '{print $1}')
        local items=$(fetch_items "$proj_" "$type" | jq -r '.[] | "\(.id) \(.title)"' | fzf --multi)
        if [[ -n "$items" ]]; then
            echo "$items" | while read -r item; do
                local item_id=$(echo "$item" | awk '{print $1}')
                update_item_milestone "$proj_" "$type" "$item_id" "$milestone_id"
            done
            done_ "Milestone set for selected items."
        else
            error_ "No items selected."
        fi
    else
        error_ "No milestone selected."
    fi
}

function fetch_milestones {
    local proj_="$1"
    local repo_=$(yq e ".projects.$proj_.server.spec.repo" $YML_PROJECTS)
    local prov_=$(yq e ".projects.$proj_.server.spec.provider" $YML_PROJECTS)
    local endpoint_=$(get_api "$prov_" ".milestones.list.endpoint")
    local method_=$(get_api "$prov_" ".milestones.list.method")
    call_api "$prov_" "$method_" "${endpoint_//:repo/$repo_}"
}

function fetch_items {
    local proj_="$1"
    local type="$2"
    local repo_=$(yq e ".projects.$proj_.server.spec.repo" $YML_PROJECTS)
    local prov_=$(yq e ".projects.$proj_.server.spec.provider" $YML_PROJECTS)
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

function update_item_milestone {
    local proj_="$1"
    local type="$2"
    local item_id="$3"
    local milestone_id="$4"
    local repo_=$(yq e ".projects.$proj_.server.spec.repo" $YML_PROJECTS)
    local prov_=$(yq e ".projects.$proj_.server.spec.provider" $YML_PROJECTS)
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

