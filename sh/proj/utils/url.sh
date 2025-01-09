function url_() {
    local service="$1"
    local provider="$2"
    local repo="$3"
    local selection="$4"

    local id=""
   
    if [[ -n "$selection" ]]; then
        case "$provider" in
            github|gitea)
                id=$(echo "$selection" | awk '{print $1}')
                ;;
            gitlab|bitbucket)
                id=$(echo "$selection" | jq -r '.iid')
                ;;
            *)
                echo "Unsupported provider: $provider"
                return 1
                ;;
        esac
    fi

    case "$provider" in
        github)
            case "$service" in
                issue) [[ -n "$id" ]] && echo "https://github.com/$repo/issues/$id" || echo "https://github.com/$repo/issues" ;;
                label) echo "https://github.com/$repo/labels" ;;
                pr) [[ -n "$id" ]] && echo "https://github.com/$repo/pulls/$id" || echo "https://github.com/$repo/pulls" ;;
                miles) echo "https://github.com/$repo/milestones" ;;
                *) echo "Invalid service: $service"; return 1 ;;
            esac
            ;;
        gitlab)
            case "$service" in
                issue) [[ -n "$id" ]] && echo "https://gitlab.com/$repo/-/issues/$id" || echo "https://gitlab.com/$repo/-/issues" ;;
                label) echo "https://gitlab.com/$repo/-/labels" ;;
                pr) [[ -n "$id" ]] && echo "https://gitlab.com/$repo/-/merge_requests/$id" || echo "https://gitlab.com/$repo/-/merge_requests" ;;
                miles) echo "https://gitlab.com/$repo/-/milestones" ;;
                *) echo "Invalid service: $service"; return 1 ;;
            esac
            ;;
        gitea)
            case "$service" in
                issue) [[ -n "$id" ]] && echo "https://gitea.com/$repo/issues/$id" || echo "https://gitea.com/$repo/issues" ;;
                label) echo "https://gitea.com/$repo/labels" ;;
                pr) [[ -n "$id" ]] && echo "https://gitea.com/$repo/pulls/$id" || echo "https://gitea.com/$repo/pulls" ;;
                miles) echo "https://gitea.com/$repo/milestones" ;;
                *) echo "Invalid service: $service"; return 1 ;;
            esac
            ;;
        bitbucket)
            case "$service" in
                issue) [[ -n "$id" ]] && echo "https://bitbucket.org/$repo/issues/$id" || echo "https://bitbucket.org/$repo/issues" ;;
                label) echo "https://bitbucket.org/$repo/labels" ;;
                pr) [[ -n "$id" ]] && echo "https://bitbucket.org/$repo/pull-requests/$id" || echo "https://bitbucket.org/$repo/pull-requests" ;;
                miles) echo "https://bitbucket.org/$repo/milestones" ;;
                *) echo "Invalid service: $service"; return 1 ;;
            esac
            ;;
        *)
            echo "Unsupported provider: $provider"
            return 1
            ;;
    esac
}

