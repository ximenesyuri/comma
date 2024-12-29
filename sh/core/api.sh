function get_api {
    yq e ".$1$2" "$YML_API"
}

function call_api {
    local provider=$1
    local method=$2
    local endpoint=$3
    local data=$4

    local base_url=$(get_api "$provider" ".base_url")
    local version=$(get_api "$provider" ".version")

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
        error_ "Unable to parse API response."
        error_ "Response: $response"
        return 1
    fi
}

