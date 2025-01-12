function method_() {
    local type_="$1"
    local prov_="$2"
    local action="$3"

    local endpoint_key
    case "$type_" in
        issue|issues) endpoint_key="issues";;
        issue.comment|issues.comment|issue.comments|issues.comments) endpoint_key="issues.comments";;
        pr|prs) endpoint_key="prs";;
        pr.comment|prs.comments|pr.comments|prs.comment) endpoint_key="prs.comments";;
        label|labels) endpoint_key="labels";;
        miles|milestone|milestones) endpoint_key="milestones";;
        *) error_ "Unsupported type: $type_"; return 1;;
    esac

    local method
    method=$(get_api "$prov_" ".${endpoint_key}.${action}.method")
    if [ -z "$method" ]; then
        error_ "Unsupported action: $action for provider: $prov_ of type: $type_"
        return 1
    fi

    echo "$method"
}

