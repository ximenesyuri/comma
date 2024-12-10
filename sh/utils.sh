function check_dependencies {
    local dependencies=("curl" "fzf" "yq" "jq")
    for cmd in "${dependencies[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "error: '$cmd' is not installed. Please install it before using this script."
            return 1
        fi
    done
}
