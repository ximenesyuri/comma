function payload_() {
    local type_="$1"
    local provider="$2"
    local action="$3"
    shift 3

    case "$type_" in
        issue|issues) issue_payload "$provider" "$action" "$@" ;;
        pr|prs) pr_payload "$provider" "$action" "$@" ;;
        label|labels) label_payload "$provider" "$action" "$@" ;;
        milestone|milestones) miles_payload "$provider" "$action" "$@" ;;
        *) error_ "Unsupported type: $type_"; return 1 ;;
    esac
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

    local payload
    case "$provider" in
        github)
            case "$action" in
                create) payload="{\"title\": \"$title\", \"body\": \"$body\", \"labels\": [$labels], \"assignee\": \"$assignee\"}" ;;
                update) payload="{\"title\": \"$title\", \"body\": \"$body\", \"state\": \"$state\"}" ;;
                *) payload="{}";;
            esac
            ;;
        gitlab|gitea|bitbucket)
            case "$action" in
                create) payload="{\"title\": \"$title\", \"description\": \"$body\", \"labels\": \"$labels\", \"assignee\": \"$assignee\"}" ;;
                update) payload="{\"title\": \"$title\", \"description\": \"$body\", \"state_event\": \"$state\"}" ;;
                *) payload="{}";;
            esac
            ;;
    esac

    echo "$payload"
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

    local payload
    case "$provider" in
        github)
            case "$action" in
                create) payload="{\"title\": \"$title\", \"body\": \"$body\", \"base\": \"$base\", \"head\": \"$head\"}" ;;
                update) payload="{\"title\": \"$title\", \"body\": \"$body\"}" ;;
                approve) payload="{\"event\": \"APPROVE\"}" ;;
                disapprove) payload="{\"event\": \"REQUEST_CHANGES\"}" ;;
                *) payload="{}";;
            esac
            ;;
        gitlab|gitea|bitbucket)
            case "$action" in
                create) payload="{\"title\": \"$title\", \"description\": \"$body\", \"source_branch\": \"$head\", \"target_branch\": \"$base\"}" ;;
                update) payload="{\"title\": \"$title\", \"description\": \"$body\"}" ;;
                *) payload="{}";;
            esac
            ;;
    esac

    echo "$payload"
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

    local payload
    case "$action" in
        create|update) payload="{\"title\": \"$title\", \"description\": \"$description\", \"due_on\": \"$due_date\"}" ;;
        *) payload="{}";;
    esac

    echo "$payload"
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

    local payload
    case "$action" in
        create|update) payload="{\"name\": \"$name\", \"color\": \"$color\", \"description\": \"$description\"}" ;;
        *) payload="{}";;
    esac

    echo "$payload"
}

