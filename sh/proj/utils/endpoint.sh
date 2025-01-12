function endpoint_ {
    local type_="$1"
    local prov_="$2"
    local repo_="$3"
    local action="$4"
    local identifier="$5"
    local endpoint

    local endpoint_key
    case "$type_" in
        issue|issues) endpoint_key="issues";;
        issue.comment|issues.comment|issue.comments|issues.comments) endpoint_key="issues.comments";;
        pr|prs) endpoint_key="prs";;
        pr.comment|prs.comment|pr.comments|prs.comments) endpoint_key="prs.comments";;
        label|labels) endpoint_key="labels";;
        miles|milestone|milestones) endpoint_key="milestones";;
        *) error_ "Unsupported type: $type_"; return 1;;
    esac

    endpoint=$(get_api "$prov_" ".${endpoint_key}.${action}.endpoint")
    if [ -z "$endpoint" ]; then
        error_ "Unsupported action: $action for provider: $prov_ of type: $type_"
        return 1
    fi

    endpoint=${endpoint//:repo/$repo_}

    case "$prov_:$type_:$action" in
        github:pr:*|github:prs:*) id_key=":number";;
        github:issue:*|github:issues:*) id_key=":issue_number";;
        github:label:*|github:labels:*) id_key=":name";;
        github:milestone:*|github:miles:*|github:milestones:*) id_key=":milestone_number";;
        github:issue.comments:list|github:issues.comments:list) id_key=":issue_number";;
        github:issue.comments:create|github:issues.comments:create) id_key=":issue_number";;
        github:issue.comments:edit|github:issues.comments:edit) id_key=":comment_id";;
        github:issue.comments:delete|github:issues.comments:delete) id_key=":comment_id";;
        github:pr.comments:list|github:prs.comments:list) id_key=":pull_number";;
        github:pr.comments:create|github:prs.comments:create) id_key=":pull_number";;
        github:pr.comments:edit|github:prs.comments:edit) id_key=":comment_id";;
        github:pr.comments:delete|github:prs.comments:delete) id_key=":comment_id";;
        gitlab:pr:*) id_key=":merge_request_id";;
        gitlab:issue:*) id_key=":issue_id";;
        gitlab:label:*) id_key=":label_id";;
        gitlab:milestone:*) id_key=":milestone_id";;
        gitlab:issue.comments:list|gitlab:issues.comments:list) id_key=":issue_id";;
        gitlab:issue.comments:create|gitlab:issues.comments:create) id_key=":issue_id";;
        gitlab:issue.comments:edit|gitlab:issues.comments:edit) id_key=":note_id";;
        gitlab:issue.comments:delete|gitlab:issues.comments:delete) id_key=":note_id";;
        gitlab:pr.comments:list|gitlab:prs.comments:list) id_key=":merge_request_id";;
        gitlab:pr.comments:create|gitlab:prs.comments:create) id_key=":merge_request_id";;
        gitlab:pr.comments:edit|gitlab:prs.comments:edit) id_key=":note_id";;
        gitlab:pr.comments:delete|gitlab:prs.comments:delete) id_key=":note_id";;
        gitea:pr:*) id_key=":index";;
        gitea:issue:*) id_key=":index";;
        gitea:label:*) id_key=":id";;
        gitea:milestone:*) id_key=":milestone_id";;
        gitea:issue.comments:list|gitea:issues.comments:list) id_key=":index";;
        gitea:issue.comments:create|gitea:issues.comments:create) id_key=":index";;
        gitea:issue.comments:edit|gitea:issues.comments:edit) id_key=":comment_id";;
        gitea:issue.comments:delete|gitea:issues.comments:delete) id_key=":comment_id";;
        gitea:pr.comments:list|gitea:prs.comments:list) id_key=":index";;
        gitea:pr.comments:create|gitea:prs.comments:create) id_key=":index";;
        gitea:pr.comments:edit|gitea:prs.comments:edit) id_key=":comment_id";;
        gitea:pr.comments:delete|gitea:prs.comments:delete) id_key=":comment_id";;
        bitbucket:pr:*) id_key=":id";;
        bitbucket:issue:*) id_key=":issue_id";;
        bitbucket:label:*) id_key=":id";;
        bitbucket:milestone:*) id_key=":milestone_id";;
        bitbucket:issue.comments:list|bitbucket:issues.comments:list) id_key=":issue_id";;
        bitbucket:issue.comments:create|bitbucket:issues.comments:create) id_key=":issue_id";;
        bitbucket:issue.comments:edit|bitbucket:issues.comments:edit) id_key=":comment_id";;
        bitbucket:issue.comments:delete|bitbucket:issues.comments:delete) id_key=":comment_id";;
        bitbucket:pr.comments:list|bitbucket:prs.comments:list) id_key=":id";;
        bitbucket:pr.comments:create|bitbucket:prs.comments:create) id_key=":id";;
        bitbucket:pr.comments:edit|bitbucket:prs.comments:edit) id_key=":comment_id";;
        bitbucket:pr.comments:delete|bitbucket:prs.comments:delete) id_key=":comment_id";;
        *) id_key="";;
    esac

    [[ -n "$identifier" ]] && endpoint=${endpoint//$id_key/$identifier}

    echo "$endpoint"
}
