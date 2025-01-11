function get_api {
    if [[ "${PROVS_[@]}" =~ "$1" ]]; then
        prov_yml="${API_[$1]}"
        yq e ".$1$2" "${prov_yml}"
    else
        error_ "get_api: '$1' is not a valid provider."
        return 1
    fi
}

function call_api {
    local provider="$1"
    local method="$2"
    local endpoint="$3"
    local data="$4"
    local body_entries="$5"

    local base_url=$(get_api "$provider" ".base_url")
    local version=$(get_api "$provider" ".version")

    local json_body=""
    if [[ -n "$body_entries" ]]; then
        json_body=$(jq -n "$body_entries")
    fi

    if [[ -n "$data" && -n "$json_body" ]]; then
        json_body=$(echo "$json_body" | jq --argjson data "$data" '. + $data')
    elif [[ -n "$data" ]]; then
        json_body="$data"
    fi

    local headers=()
    local token_header=""
    local accept_header=""
    local version_header=""

    case $provider in
        github)
            if [[ -n "$GITHUB_TOKEN" ]]; then
                token_header="Authorization: Bearer $GITHUB_TOKEN"
            else
                error_ "GITHUB_TOKEN is not set."
                return 1
            fi
            accept_header="Accept: application/vnd.github+json"
            version_header="X-GitHub-Api-Version: 2022-11-28"
            ;;
        gitlab)
            if [[ -n "$GITLAB_TOKEN" ]]; then
                token_header="PRIVATE-TOKEN: $GITLAB_TOKEN"
            else
                error_ "GITLAB_TOKEN is not set."
                return 1
            fi
            ;;
        gitea)
            if [[ -n "$GITEA_TOKEN" ]]; then
                token_header="Authorization: token $GITEA_TOKEN"
            else
                error_ "GITEA_TOKEN is not set."
                return 1
            fi
            ;;
        bitbucket)
            if [[ -n "$BITBUCKET_USERNAME" && -n "$BITBUCKET_TOKEN" ]]; then
                headers+=("-u" "$BITBUCKET_USERNAME:$BITBUCKET_TOKEN")
            else
                error_ "BITBUCKET_USERNAME or BITBUCKET_TOKEN is not set."
                return 1
            fi
            ;;
        *)
            error_ "Provider '$provider' is not supported."
            return 1
            ;;
    esac

    headers+=("-H" "$token_header")
    [[ -n "$accept_header" ]] && headers+=("-H" "$accept_header")
    [[ -n "$version_header" ]] && headers+=("-H" "$version_header")

    response=$(curl -L -s -X "$method" "${headers[@]}" -d "$json_body" "$base_url/$endpoint")

    if echo "$response" | jq empty 2>/dev/null; then
        echo "$response"
    else
        error_ "Unable to parse API response."
        error_ "Response:"
        line_
        echo -e "$response"
        line_
        return 1
    fi
}

