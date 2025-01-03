function get_api {
    yq e ".$1$2" "$YML_API"
}

function call_api {
    local provider=$1
    local method=$2
    local endpoint=$3
    local data=$4
    local body_entries=$5

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

    case $provider in
        github)
            if [ -z "$GITHUB_TOKEN" ]; then
                echo "error: GITHUB_TOKEN is not set."
                return 1
            fi
            response=$(curl -s -X "$method" \
                -H "Authorization: token $GITHUB_TOKEN" \
                -H "Accept: application/vnd.github.v3+json" \
                -d "$json_body" \
                "$base_url/$endpoint")
            ;;
        gitlab)
            local token="$GITLAB_TOKEN"
            response=$(curl -s -X "$method" \ 
                -H "PRIVATE-TOKEN: $token"  \ 
                -d "$json_body" \ 
                "$base_url/$version/$endpoint")
            ;;
        gitea)
            local token="$GITEA_TOKEN"
            response=$(curl -s -X "$method" \ 
                -H "Authorization: token $token" \ 
                -d "$json_body" \
                "$base_url/$version/$endpoint")
            ;;
        bitbucket)
            response=$(curl -s -X "$method" \ 
                -u "$BITBUCKET_USERNAME:$BITBUCKET_TOKEN"  \ 
                -d "$json_body" "$base_url/$endpoint")
            ;;
        *)
            error_ "Provider '$provider' is not supported."
            return 1
            ;;
    esac

    if echo "$response" | jq empty 2>/dev/null; then
        echo "$response"
    else
        error_ "Unable to parse API response."
        error_ "Response: $response"
        return 1
    fi
}

