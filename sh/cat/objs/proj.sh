function open_proj(){
    project_name="$1"
    provider=$(get_proj "$project_name" ".server.provider" | envsubst )
    repo=$(get_proj "$project_name" ".server.repo" | envsubst )
    if [[ -n "$path" ]]; then
        cd $path
    fi
}

function list_proj {
    if [[ -n "${PROJS_[@]}" ]]; then
        echo "Projects:"
        for proj in ${PROJS_[@]}; do
            echo "- $proj" 
        done
    else
        echo "No projects found."
    fi
}

function new_proj {
    echo "Enter new project name:"
    read -e -r -p "> " project_name
    if [[ -n "$project_name" ]]; then
        echo "Allow issues? (true/false)"
        read -e -r -p "> " issues
        echo "Enter custom labels for this project (comma-separated):"
        read -e -r -p "> " custom_labels

        yq e -i ".projects.${project_name}.issues = $issues" "$COMMA_CONF"
        yq e -i ".projects.${project_name}.labels = [\"${custom_labels//,/\", \"}\"]" "$COMMA_CONF"

        echo "Project '$project_name' added with custom labels '${custom_labels}'."
    else
        echo "Project name cannot be empty."
    fi
}

function edit_proj(){
    echo "TBA"
}

function remove_proj {
    local projects
    projects=$(g_get_projects)
    if [[ -n "${projects}" ]]; then
        local project_name
        project_name=$(echo "$projects" | fzf --prompt="Select a project to remove: $fzf_geometry") || return 1
        echo "Are you sure you want to delete the project '$project_name'? (y/n)"
        read -e -r -p "> " confirm
        if [[ "$confirm" == "y" ]]; then
            yq e -i "del(.projects.\"${project_name}\")" "$COMMA_CONF"
            echo "Project '$project_name' removed."
        else
            echo "Project removal canceled."
        fi
    else
        echo "There are no projects to remove."
    fi
}

