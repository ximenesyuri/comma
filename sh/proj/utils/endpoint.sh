function issue_endpoint {
    local provider="$1"
    local action="$2"
    local repo="$3"
    local issue_number="$4"

    local endpoint=$(get_api "$provider" ".issues.${action}.endpoint")

    case "$provider" in
        github)
            case "$action" in
                list)
                    endpoint=${endpoint//:repo/$repo}
                    ;;
                update|comments)
                    endpoint=${endpoint//:repo/$repo}
                    endpoint=${endpoint//:issue_number/$issue_number}
                    ;;
                *)
                    error_ "Unsupported action: $action for provider: $provider"
                    return 1
                    ;;
            esac
            ;;
        gitlab)
            case "$action" in
                list)
                    endpoint=${endpoint//:repo/$repo}
                    ;;
                update|comments)
                    endpoint=${endpoint//:repo/$repo}
                    endpoint=${endpoint//:issue_id/$issue_number}
                    ;;
                *)
                    error_ "Unsupported action: $action for provider: $provider"
                    return 1
                    ;;
            esac
            ;;
        gitea)
            case "$action" in
                list)
                    endpoint=${endpoint//:repo/$repo}
                    ;;
                update|comments)
                    endpoint=${endpoint//:repo/$repo}
                    endpoint=${endpoint//:index/$issue_number}
                    ;;
                *)
                    error_ "Unsupported action: $action for provider: $provider"
                    return 1
                    ;;
            esac
            ;;
        bitbucket)
            case "$action" in
                list)
                    endpoint=${endpoint//:repo/$repo}
                    ;;
                update|comments)
                    endpoint=${endpoint//:repo/$repo}
                    endpoint=${endpoint//:issue_id/$issue_number}
                    ;;
                *)
                    error_ "Unsupported action: $action for provider: $provider"
                    return 1
                    ;;
            esac
            ;;
        *)
            error_ "Unsupported provider: $provider"
            return 1
            ;;
    esac

    echo "$endpoint"
}

function label_endpoint {
    local provider="$1"
    local action="$2"
    local repo="$3"
    local name="$4"

    local endpoint=$(get_api "$provider" ".labels.${action}.endpoint")

    case "$provider" in
        github|gitlab|gitea|bitbucket)
            case "$action" in
                list)
                    endpoint=${endpoint//:repo/$repo}
                    ;;
                delete|edit)
                    endpoint=${endpoint//:repo/$repo}
                    endpoint=${endpoint//:name/$name}
                    ;;
                *)
                    error_ "Unsupported action: $action for provider: $provider"
                    return 1
                    ;;
            esac
            ;;
        *)
            error_ "Unsupported provider: $provider"
            return 1
            ;;
    esac

    echo "$endpoint"
}

function pr_endpoint {
    local provider="$1"
    local action="$2"
    local repo="$3"
    local pull_number="$4"

    local endpoint=$(get_api "$provider" ".prs.${action}.endpoint")

    case "$provider" in
        github)
            case "$action" in
                list)
                    endpoint=${endpoint//:repo/$repo}
                    ;;
                new|update|approve|disapprove)
                    endpoint=${endpoint//:repo/$repo}
                    endpoint=${endpoint//:pull_number/$pull_number}
                    ;;
                *)
                    error_ "Unsupported action: $action for provider: $provider"
                    return 1
                    ;;
            esac
            ;;
        gitlab)
            case "$action" in
                list)
                    endpoint=${endpoint//:repo/$repo}
                    ;;
                new|update|approve|disapprove)
                    endpoint=${endpoint//:repo/$repo}
                    endpoint=${endpoint//:merge_request_iid/$pull_number}
                    ;;
                *)
                    error_ "Unsupported action: $action for provider: $provider"
                    return 1
                    ;;
            esac
            ;;
        gitea)
            case "$action" in
                list)
                    endpoint=${endpoint//:repo/$repo}
                    ;;
                new|update|approve|disapprove)
                    endpoint=${endpoint//:repo/$repo}
                    endpoint=${endpoint//:index/$pull_number}
                    ;;
                *)
                    error_ "Unsupported action: $action for provider: $provider"
                    return 1
                    ;;
            esac
            ;;
        bitbucket)
            case "$action" in
                list)
                    endpoint=${endpoint//:repo/$repo}
                    ;;
                new|update|approve|disapprove)
                    endpoint=${endpoint//:repo/$repo}
                    endpoint=${endpoint//:id/$pull_number}
                    ;;
                *)
                    error_ "Unsupported action: $action for provider: $provider"
                    return 1
                    ;;
            esac
            ;;
        *)
            error_ "Unsupported provider: $provider"
            return 1
            ;;
    esac

    echo "$endpoint"
}
