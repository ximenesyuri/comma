function endpoint_ {
    local type_="$1"
    local prov_="$2"
    local repo_="$3"
    local action="$4"
    local identifier="$5"
    local endpoint

    local endpoint_key
    case "$type_" in
        i|issue|issues) endpoint_key="issues";;
        p|pr|prs) endpoint_key="prs";;
        l|label|labels) endpoint_key="labels";;
        m|miles|milestone|milestones) endpoint_key="milestones";;
        *) error_ "Unsupported type: $type_"; return 1;;
    esac

    endpoint=$(get_api "$prov_" ".${endpoint_key}.${action}.endpoint")
    if [ -z "$endpoint" ]; then
        error_ "Unsupported action: $action for provider: $prov_ of type: $type_"
        return 1
    fi

    endpoint=${endpoint//:repo/$repo_}

    case "$prov_:$type_:$action" in
        github:pr:*) id_placeholder=":number";;
        github:issue:*) id_placeholder=":issue_number";;
        github:label:*) id_placeholder=":name";;
        github:milestone:*) id_placeholder=":milestone_number";;
        gitlab:pr:*) id_placeholder=":merge_request_id";;
        gitlab:issue:*) id_placeholder=":issue_id";;
        gitlab:label:*) id_placeholder=":label_id";;
        gitlab:milestone:*) id_placeholder=":milestone_id";;
        gitea:pr:*) id_placeholder=":index";;
        gitea:issue:*) id_placeholder=":index";;
        gitea:label:*) id_placeholder=":id";;
        gitea:milestone:*) id_placeholder=":milestone_id";;
        bitbucket:pr:*) id_placeholder=":id";;
        bitbucket:issue:*) id_placeholder=":issue_id";;
        bitbucket:label:*) id_placeholder=":id";;
        bitbucket:milestone:*) id_placeholder=":milestone_id";;
        *) id_placeholder="";;
    esac

    [[ -n "$identifier" ]] && endpoint=${endpoint//$id_placeholder/$identifier}

    echo "$endpoint"
}
