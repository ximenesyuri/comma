#!/bin/bash

CONFIG_FILE="${BASH_SOURCE%/*}/yml/g.yml"
API_CONFIG_FILE="${BASH_SOURCE%/*}/yml/api.yml"

function load_configuration {
    local key=$1
    yq e ".${key}" "$CONFIG_FILE"
}

function get_projects {
    yq e '.projects | keys | .[]' "$CONFIG_FILE"
}

function get_project_info {
    local project_name=$1
    yq e ".projects.${project_name}" "$CONFIG_FILE"
}

function get_api_info {
    local provider=$1
    local key=$2
    yq e ".${provider}.${key}" "$API_CONFIG_FILE"
}

BROWSER_CMD=$(load_configuration "globals.browser")
EDITOR_CMD=$(load_configuration "globals.editor")
GLOBAL_LABELS=($(yq e '.globals.labels[]' "$CONFIG_FILE"))
fzf_geometry="--height=20% --layout=reverse"

function call_api {
   local provider=$1
   local method=$2
   local endpoint=$3
   local data=$4

   local base_url=$(get_api_info "$provider" "base_url")
   local version=$(get_api_info "$provider" "version")

    case $provider in
        github)
            if [ -z "$GITHUB_TOKEN" ]; then
                echo "error: GITHUB_TOKEN is not set."
                return 1
            fi
            response=$(curl -s -X "$method" \
                -H "Authorization: token $GITHUB_TOKEN" \
                -H "Accept: application/vnd.github.v3+json" \
                -d "$data" \
                "$base_url/$endpoint")

            echo "$response"
            ;;
        gitlab)
            local token="$GITLAB_TOKEN"  # Replace with actual token
            curl -s -X "$method" -H "PRIVATE-TOKEN: $token" -d "$data" "$base_url/$version/$endpoint"
            ;;
        gitea)
            local token="$GITEA_TOKEN"  # Replace with actual token
            curl -s -X "$method" -H "Authorization: token $token" -d "$data" "$base_url/$version/$endpoint"
            ;;
        *)
            echo "error: Unsupported provider '$provider'."
            return 1
            ;;
    esac
}

function g {
    function check_dependencies {
        local dependencies=("curl" "fzf" "yq" "jq")
        for cmd in "${dependencies[@]}"; do
            if ! command -v "$cmd" &> /dev/null; then
                echo "error: '$cmd' is not installed. Please install it before using this script."
                return 1
            fi
        done 
    }

    function show_help {
        echo "Usage: todo [command] or todo [project] [action]

Commands:
    new           Add a new project to the todo list
    rm            Remove a project from the todo list
    ls            List all projects
    help, --help  Show this help message

Actions for a project:
    new                  Create a new issue
    close [filter]       Close an issue with specified ID
    reopen [filter]      Reopen a closed issue with specified ID
    ls                   List issues
    edit                 Edit a selected issue (title, description, labels)
    "
    }

    function todo_new {
        echo "Enter new project name:"
        read -e -r -p "> " project_name
        if [[ -n "$project_name" ]]; then
            echo "Allow issues? (true/false)"
            read -e -r -p "> " issues
            echo "Enter custom labels for this project (comma-separated):"
            read -e -r -p "> " custom_labels

            yq e -i ".projects.${project_name}.issues = $issues" "$CONFIG_FILE"
            yq e -i ".projects.${project_name}.labels = [\"${custom_labels//,/\", \"}\"]" "$CONFIG_FILE"

            echo "Project '$project_name' added with custom labels '${custom_labels}'."
        else
            echo "Project name cannot be empty."
        fi
    }

    function todo_rm {
        local projects
        projects=$(get_projects)
        if [[ -n "${projects}" ]]; then
            local project_name
            project_name=$(echo "$projects" | fzf --prompt="Select a project to remove: $fzf_geometry") || return 1
            echo "Are you sure you want to delete the project '$project_name'? (y/n)"
            read -e -r -p "> " confirm
            if [[ "$confirm" == "y" ]]; then
                yq e -i "del(.projects.\"${project_name}\")" "$CONFIG_FILE"
                echo "Project '$project_name' removed."
            else
                echo "Project removal canceled."
            fi
        else
            echo "There are no projects to remove."
        fi
    }

    function todo_ls {
        local projects
        projects=$(get_projects)
        if [[ -n "${projects}" ]]; then
            echo "Projects:"
            echo "$projects" | while read -r project; do
                echo "- $project"
            done
        else
            echo "No projects found."
        fi
    }

    function manage_issues {
        local action="$1"
        local project_name="$2"
        local state="$3"

        local project_config
        project_config=$(get_project_info "$project_name")

        if [[ $(yq e '.issues' <<< "$project_config") != "true" ]]; then
            echo "error: Project '$project_name' does not support issues."
            return 1
        fi

        local project_repo=$(yq e '.repo' <<< "$project_config")
        local provider=$(yq e '.provider' <<< "$project_config")
        local endpoint_list=$(get_api_info "$provider" "issues.list.endpoint")
        local full_endpoint="${endpoint_list//:repo/$project_repo}?state=${state}"
        issues=$(call_api "$provider" "GET" "$full_endpoint") 

        if [[ -n "${issues}" ]]; then
            local selection
            selection=$(echo "$issues" | jq -r '.[] | "\(.number) \(.title)"' | fzf $fzf_geometry)
            if [[ -n "${selection}" ]]; then
                local issue_id=$(echo "${selection}" | awk '{print $1}')

                if [[ "$action" == "edit" ]]; then
                    edit_issue "$project_name" "$issue_id"
                else
                    display_issue "$project_repo" "$issue_id"
                fi
            else
                echo "No issue selected."
            fi
        else
            echo "There are no issues to select from."
        fi
    }

    function display_issue {
        local project_repo="$1"
        local issue_id="$2"
        local project_provider
        project_provider=$(get_project_info "$project_name" | yq e '.provider')
        local endpoint_display=$(get_api_info "$project_provider" "issues.list.endpoint")
        issue=$(call_api "$project_provider" "GET" "${endpoint_display//:repo/$project_repo}/$issue_id")

        local owner=$(echo "$issue" | jq -r '.user.login')
        local title=$(echo "$issue" | jq -r '.title')
        local created_at=$(echo "$issue" | jq -r '.created_at')
        local updated_at=$(echo "$issue" | jq -r '.updated_at')
        local comments_count=$(echo "$issue" | jq -r '.comments')
        local body=$(echo "$issue" | jq -r '.body')
        local issue_url=$(echo "$issue" | jq -r '.html_url')
        local labels=$(echo "$issue" | jq -r '.labels[].name' | paste -sd ", " -)

        local blue="\033[34m"
        local magenta="\033[35m"
        local reset="\033[0m"
        
        echo ""
        echo -e "${blue}Project:${reset}         $project_repo"
        echo -e "${blue}ID:${reset}              $issue_id"
        echo -e "${blue}URL:${reset}             $issue_url"
        echo -e "${magenta}----------------------------------${reset}"
        echo -e "${blue}Owner:${reset}           $owner"
        echo -e "${blue}Title:${reset}           $title"
        echo -e "${blue}Creation Date:${reset}   $created_at"
        echo -e "${blue}Last Change:${reset}     $updated_at"
        echo -e "${blue}Comments:${reset}        $comments_count"
        echo -e "${blue}Labels:${reset}          $labels"
        echo -e "${magenta}-----------------------------------${reset}"
        echo -e "${blue}Description:${reset}"
        echo "$body" | fold -sw 80 | while IFS= read -r line; do
            echo "    > $line"
        done
        echo -e "${magenta}-----------------------------------${reset}"
    } 

    function new_issue {
        local project_name="$1"
        local project_config
        project_config=$(get_project_info "$project_name")

        if [[ $(yq e '.issues' <<< "$project_config") != "true" ]]; then
            echo "error: Project '$project_name' does not support issues."
            return 1
        fi

        local project_repo=$(yq e '.repo' <<< "$project_config")
        local provider=$(yq e '.provider' <<< "$project_config")

        if [[ -z "$project_repo" || "$project_repo" == "null" ]]; then
            echo "error: No valid repository found for project '$project_name'."
            return 1
        fi

        local project_labels=($(yq e '.labels[]' <<< "$project_config"))
        local labels=("${GLOBAL_LABELS[@]}" "${project_labels[@]}")

        echo "Enter issue title:"
        read -e -r -p "> " title
        echo "Enter issue description:"
        read -e -r -p "> " description

        echo "Select labels (comma separated): ${labels[*]}"
        read -e -r -p "> " selected_labels
        local endpoint_create=$(get_api_info "$provider" "issues.create.endpoint")
        call_api "$provider" "POST" "${endpoint_create//:repo/$project_repo}" "{\"title\": \"${title}\", \"body\": \"${description}\", \"labels\": [${selected_labels// /,}]}"

        if [[ $? -eq 0 ]]; then
            echo "ok: The issue has been created."
        else
            echo "error: Failed to create the issue. Please check your API token and permissions."
        fi
    }

    function edit_issue {
        local project_name="$1"
        local issue_id="$2"
        local project_config
        project_config=$(get_project_info "$project_name")
        local provider=$(yq e '.provider' <<< "$project_config")
        
        if [[ $(yq e '.issues' <<< "$project_config") != "true" ]]; then
            echo "error: Project '$project_name' does not support issues."
            return 1
        fi

        local project_repo=$(yq e '.repo' <<< "$project_config")
        local endpoint_get=$(get_api_info "$provider" "issues.list.endpoint")
        issue=$(call_api "$provider" "GET" "${endpoint_get//:repo/$project_repo}/$issue_id")
        
        local title=$(echo "$issue" | jq -r '.title')
        local body=$(echo "$issue" | jq -r '.body')
        local existing_labels=($(echo "$issue" | jq -r '.labels[].name'))

        echo "Current Title: $title"
        echo "Enter new title (leave empty to keep current):"
        read -e -r -p "> " new_title
        new_title=${new_title:-$title}

        echo -e "Current Description:\n$body"
        echo "Enter new description (leave empty to keep current):"
        read -e -r -p "> " new_body
        new_body=${new_body:-$body}
        
        local project_labels=($(yq e '.labels[]' <<< "$project_config"))
        local available_labels=("${GLOBAL_LABELS[@]}" "${project_labels[@]}")

        echo "Current Labels: ${existing_labels[*]}"
        echo "Available Labels: ${available_labels[*]}"
        echo "Enter new labels (comma-separated, leave empty to keep current):"
        read -e -r -p "> " new_labels
        new_labels=(${new_labels//,/ })

        if [[ -z ${new_labels[*]} ]]; then
            new_labels=("${existing_labels[@]}")
        fi

        local endpoint_update=$(get_api_info "$provider" "issues.update.endpoint")
        call_api "$provider" "PATCH" "${endpoint_update//:repo/$project_repo}/$issue_id" "{\"title\": \"${new_title}\", \"body\": \"${new_body}\", \"labels\": ${new_labels[@]}}" > /dev/null 2>&1

        if [[ $? -eq 0 ]]; then
            echo "ok: The issue has been updated."
            display_issue "$project_repo" "$issue_id"
        else
            echo "error: Failed to update the issue. Please check your API token and permissions."
        fi
    }

    check_dependencies || return 1

    local first_arg="$1"

    if [[ "$first_arg" != "help" && "$first_arg" != "--help" && "$first_arg" != "new" && "$first_arg" != "rm" && "$first_arg" != "ls" ]]; then
        local project_name="$1"
        shift
        case "$1" in
            n|new)
                new_issue "$project_name"
                ;;
            c|close)
                shift
                manage_issues "closed" "$project_name" "open"
                ;;
            r|reopen)
                shift
                manage_issues "open" "$project_name" "closed"
                ;;
            l|list|ls)
                manage_issues "ls" "$project_name" "all"
                ;;
            e|edit)
                manage_issues "edit" "$project_name" "open"
                ;;
            *)
                show_help
                ;;
        esac
    else
        case "$first_arg" in
            new)
                todo_new
                ;;
            rm)
                todo_rm
                ;;
            ls)
                todo_ls
                ;;
            help|--help)
                show_help
                ;;
            *)
                show_help
                ;;
        esac
    fi
}

function _g_complete {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    local opts="new rm ls help"
    local actions="new close reopen ls edit"
    local projects=$(get_projects)

    if [[ ${COMP_CWORD} == 1 ]]; then
        COMPREPLY=($(compgen -W "${opts} ${projects}" -- "${cur}"))
    elif [[ ${COMP_CWORD} == 2 && "${projects}" == *"${prev}"* ]]; then
        COMPREPLY=($(compgen -W "${actions}" -- "${cur}"))
    fi

    return 0
}

complete -F _g_complete g

