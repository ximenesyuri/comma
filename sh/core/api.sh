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

    if is_null_ "$method"; then
        error_  "API Error: Received a null method."
        if is_null_ "$endpoint"; then
            error_  "API Error: Received a null endpoint."
            return 1
        fi
        return 1
    fi
    
    
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
                error_ "API Error: GITHUB_TOKEN is not set."
                return 1
            fi
            accept_header="Accept: application/vnd.github+json"
            version_header="X-GitHub-Api-Version: 2022-11-28"
            ;;
        gitlab)
            if [[ -n "$GITLAB_TOKEN" ]]; then
                token_header="PRIVATE-TOKEN: $GITLAB_TOKEN"
            else
                error_ "API Error: GITLAB_TOKEN is not set."
                return 1
            fi
            ;;
        gitea)
            if [[ -n "$GITEA_TOKEN" ]]; then
                token_header="Authorization: token $GITEA_TOKEN"
            else
                error_ "API Error: GITEA_TOKEN is not set."
                return 1
            fi
            ;;
        bitbucket)
            if [[ -n "$BITBUCKET_USERNAME" && -n "$BITBUCKET_TOKEN" ]]; then
                headers+=("-u" "$BITBUCKET_USERNAME:$BITBUCKET_TOKEN")
            else
                error_ "API Error: BITBUCKET_USERNAME or BITBUCKET_TOKEN is not set."
                return 1
            fi
            ;;
        *)
            error_ "API Error: Provider '$provider' is not supported."
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
        debug_ "PROVIDER: $provider"
        debug_ "ENDPOINT: $endpoint"
        debug_ "METHOD: $method"
        debug_ "DATA: $data"
        debug_ "BODY: $body_entries"
        debug_ "HEADERS:"
        for header in "${headers[@]}"; do
            debug_ "- $header"
        done
        debug_ "RESPONSE:"
        line_
        echo -e "$response"
        line_
        return 1
    fi
}


function response_() {
    local response="$1"

    if [[ -z "$response" ]]; then
        warn_ "API Warn: Empty response received."
        return 0
    fi

    local response_type
    response_type=$(echo "$response" | jq -r 'type')

    if [[ "$response_type" != "array" ]]; then
        if echo "$response" | jq -e 'has("message")' >/dev/null; then
            local message=$(echo "$response" | jq -r '.message')
            if [[ -n "$message" ]]; then
                error_ "API Error: $message"
                return 1
            fi
        fi

        if echo "$response" | jq -e 'has("status_code")' >/dev/null; then
            local status_code=$(echo "$response" | jq -r '.status_code')
            if [[ "$status_code" =~ ^(200|201|204)$ ]]; then
                return 0
            else
                error_ "API Error: Unexpected status code $status_code"
                return 1
            fi
        fi

        if echo "$response" | jq -e 'has("error")' >/dev/null; then
            local error=$(echo "$response" | jq -r '.error')
            if [[ -n "$error" ]]; then
                error_ "API Error: $error"
                return 1
            fi
        fi
    else 
        return 0
    fi
 
    return 0
}
