function payload_(){
    proj_=$1
}

function issue_payload {
    local provider="$1"
    local action="$2"
    shift 2

    local title body labels assignee state
    for arg in "$@"; do
        case $arg in
            title=*) title="${arg#*=}" ;;
            body=*) body="${arg#*=}" ;;
            labels=*) labels="${arg#*=}" ;;
            assignee=*) assignee="${arg#*=}" ;;
            state=*) state="${arg#*=}" ;;
        esac
    done

    case "$provider" in
        github)
            case "$action" in
                create)
                    echo "{\"title\": \"$title\", \"body\": \"$body\", \"labels\": [$labels], \"assignee\": \"$assignee\"}"
                    ;;
                update)
                    echo "{\"title\": \"$title\", \"body\": \"$body\", \"state\": \"$state\"}"
                    ;;
                list|comment)
                    echo "{}"
                    ;;
                *)
                    error_ "Unsupported action: $action for provider: $provider"
                    return 1
                    ;;
            esac
            ;;
        gitlab|gitea|bitbucket)
            case "$action" in
                create)
                    echo "{\"title\": \"$title\", \"description\": \"$body\", \"labels\": [$labels], \"assignee\": \"$assignee\"}"
                    ;;
                update)
                    echo "{\"title\": \"$title\", \"description\": \"$body\", \"state_event\": \"$state\"}"
                    ;;
                list|comment)
                    echo "{}"
                    ;;
                *)
                    error_ "Unsupported action: $action for provider: $provider"
                    return 1
                    ;;
            esac
            ;;
        *)
            error_ "Unsupported provider: $provider"
            return 1
            ;;
    esac
}

function pr_payload {
    local provider="$1"
    local action="$2"
    shift 2

    local title body base head
    for arg in "$@"; do
        case $arg in
            title=*) title="${arg#*=}" ;;
            body=*) body="${arg#*=}" ;;
            base=*) base="${arg#*=}" ;;
            head=*) head="${arg#*=}" ;;
        esac
    done

    case "$provider" in
        github)
            case "$action" in
                create)
                    echo "{\"title\": \"$title\", \"body\": \"$body\", \"base\": \"$base\", \"head\": \"$head\"}"
                    ;;
                update)
                    echo "{\"title\": \"$title\", \"body\": \"$body\"}"
                    ;;
                approve)
                    echo "{\"event\": \"APPROVE\"}"
                    ;;
                disapprove)
                    echo "{\"event\": \"REQUEST_CHANGES\"}"
                    ;;
                list)
                    echo "{}"
                    ;;
                *)
                    error_ "Unsupported action: $action for provider: $provider"
                    return 1
                    ;;
            esac
            ;;
        gitlab|gitea|bitbucket)
            case "$action" in
                create)
                    echo "{\"title\": \"$title\", \"description\": \"$body\", \"source_branch\": \"$base\", \"target_branch\": \"$head\"}"
                    ;;
                update)
                    echo "{\"title\": \"$title\", \"description\": \"$body\"}"
                    ;;
                list)
                    echo "{}"
                    ;;
                *)
                    error_ "Unsupported action: $action for provider: $provider"
                    return 1
                    ;;
            esac
            ;;
        *)
            error_ "Unsupported provider: $provider"
            return 1
            ;;
    esac
}

function miles_payload {
    local provider="$1"
    local action="$2"
    shift 2

    local title description due_date
    for arg in "$@"; do
        case $arg in
            title=*) title="${arg#*=}" ;;
            desc=*) description="${arg#*=}" ;;
            due_date=*) due_date="${arg#*=}" ;;
        esac
    done

    case "$action" in
        create|update)
            echo "{\"title\": \"$title\", \"description\": \"$description\", \"due_on\": \"$due_date\"}"
            ;;
        list)
            echo "{}"
            ;;
        *)
            error_ "Unsupported action: $action for provider: $provider"
            return 1
            ;;
    esac
}

function label_payload {
    local provider="$1"
    local action="$2"
    shift 2

    local name color description
    for arg in "$@"; do
        case $arg in
            name=*) name="${arg#*=}" ;;
            color=*) color="${arg#*=}" ;;
            desc=*) description="${arg#*=}" ;;
        esac
    done

    case "$action" in
        create|update)
            echo "{\"name\": \"$name\", \"color\": \"$color\", \"description\": \"$description\"}"
            ;;
        list)
            echo "{}"
            ;;
        *)
            error_ "Unsupported action: $action for provider: $provider"
            return 1
            ;;
    esac
}

