function endpoint_ {
    local type="$1"
    local proj_="$2"
    local action="$3"
    local identifier="$4"

    local provider=$(yq ".projects.${proj_}.spec.provider" "$YML_PROJECTS")
    local repo=$(yq ".projects.${proj_}.spec.repo" "$YML_PROJECTS")

    if [[ -z "$provider" || -z "$repo" ]]; then
        error_ "Provider or repo not set for project '$proj_'."
        return 1
    fi

    local endpoint

    case "$type" in
        issue|issues)
            endpoint=$(get_api "$provider" ".issues.${action}.endpoint")
            case "$provider" in
                github|gitlab|gitea|bitbucket)
                    case "$action" in
                        list|get)
                            endpoint=${endpoint//:repo/$repo}
                            if [[ "$action" == "list" ]] && [[ -n "$identifier" ]]; then
                                if [[ "$provider" =~ github|gitea ]]; then
                                    endpoint=${endpoint//:issue_number/$identifier}
                                else
                                    endpoint=${endpoint//:issue_id/$identifier}
                                fi
                            fi
                            ;;
                        *)
                            error_ "Unsupported action: $action for provider: $provider of type: $type"
                            return 1
                            ;;
                    esac
                    ;;
                *)
                    error_ "Unsupported provider: $provider for type: $type"
                    return 1
                    ;;
            esac
            ;;
        label)
            endpoint=$(get_api "$provider" ".labels.${action}.endpoint")
            case "$provider" in
                github|gitlab|gitea|bitbucket)
                    case "$action" in
                        list)
                            endpoint=${endpoint//:repo/$repo}
                            ;;
                        delete|edit)
                            endpoint=${endpoint//:repo/$repo}
                            endpoint=${endpoint//:name/$identifier}
                            ;;
                        *)
                            error_ "Unsupported action: $action for provider: $provider of type: $type"
                            return 1
                            ;;
                    esac
                    ;;
                *)
                    error_ "Unsupported provider: $provider for type: $type"
                    return 1
                    ;;
            esac
            ;;
        pr)
            endpoint=$(get_api "$provider" ".prs.${action}.endpoint")
            case "$provider" in
                github)
                    case "$action" in
                        list)
                            endpoint=${endpoint//:repo/$repo}
                            ;;
                        new|update|approve|disapprove)
                            endpoint=${endpoint//:repo/$repo}
                            endpoint=${endpoint//:pull_number/$identifier}
                            ;;
                        *)
                            error_ "Unsupported action: $action for provider: $provider of type: $type"
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
                            endpoint=${endpoint//:merge_request_iid/$identifier}
                            ;;
                        *)
                            error_ "Unsupported action: $action for provider: $provider of type: $type"
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
                            endpoint=${endpoint//:index/$identifier}
                            ;;
                        *)
                            error_ "Unsupported action: $action for provider: $provider of type: $type"
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
                            endpoint=${endpoint//:id/$identifier}
                            ;;
                        *)
                            error_ "Unsupported action: $action for provider: $provider of type: $type"
                            return 1
                            ;;
                    esac
                    ;;
                *)
                    error_ "Unsupported provider: $provider for type: $type"
                    return 1
                    ;;
            esac
            ;;
        *)
            error_ "Unsupported type: $type"
            return 1
            ;;
    esac

    echo "$endpoint"
}
