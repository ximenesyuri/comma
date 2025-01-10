
function proj_get(){
    local proj_="$2"
    local info_="$1"
    local proj_str=".projects.$proj_"
    if [[ -z "$proj_" ]]; then
        error_ "proj_get: missing 'proj_'."
        return 1
    else
        case $info_ in 
            repo|r|repository)
                yq e "$proj_str.spec.repo"  $YML_PROJECTS ;;
            prov|pv|provider)
                yq e "$proj_str.spec.provider"  $YML_PROJECTS ;;
            *)
                error_ "proj_get: '$info_' is not a valid project info."
                return 1
                ;;
        esac
    fi      
}

function proj_allow(){
    local proj_="$2"
    local serv_="$1"
    local proj_str=".projects.$proj_"
    if [[ -z "$proj_" ]]; then
        error_ "proj_get: missing 'proj_'."
        return 1
    else
        case $serv_ in 
            i|issue|issues)
                yq e "$proj_str.spec.services.issues"  $YML_PROJECTS ;;
            l|label|labels)
                yq e "$proj_str.spec.services.labels"  $YML_PROJECTS ;;
            p|pr|pull-request|pull-requests)
                yq e "$proj_str.spec.services.prs"  $YML_PROJECTS ;;
            *)
                error_ "proj_allow: '$serv_' is not a valid project service."
                return 1
                ;;
        esac
    fi
}
