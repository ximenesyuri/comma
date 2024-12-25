function g_get_api_info {
    local provider=$1
    local key=$2
    yq e ".${provider}.${key}" "$G_API"
}

function call_api {
    local provider=$1
    local method=$2
    local endpoint=$3
    local data=$4

    local base_url=$(g_get_api_info "$provider" "base_url")
    local version=$(g_get_api_info "$provider" "version")

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
            ;;
        gitlab)
            local token="$GITLAB_TOKEN"
            response=$(curl -s -X "$method" -H "PRIVATE-TOKEN: $token" -d "$data" "$base_url/$version/$endpoint")
            ;;
        gitea)
            local token="$GITEA_TOKEN"
            response=$(curl -s -X "$method" -H "Authorization: token $token" -d "$data" "$base_url/$version/$endpoint")
            ;;
        *)
            echo "error: Unsupported provider '$provider'."
            return 1
            ;;
    esac
    
    if echo "$response" | jq empty 2>/dev/null; then
        echo "$response"
    else
        echo "error: Unable to parse API response. Response: $response"
        return 1
    fi
}

