
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
            issue|issues)
                if is_true_ $(yq e "$proj_str.spec.services.issues"  $YML_PROJECTS); then
                    return 0
                else
                    error_ "Project '$proj_' does not allow issues."
                    return 1
                fi
                ;;
            miles|milestone|milestones)
                if is_true_ $(yq e "$proj_str.spec.services.miles"  $YML_PROJECTS); then
                    return 0
                else
                    error_ "Project '$proj_' does not allow miles."
                    return 1
                fi
                ;;
            label|labels)
                if is_true_ $(yq e "$proj_str.spec.services.labels"  $YML_PROJECTS); then
                    return 0
                else
                    error_ "Project '$proj_' does not allow labels."
                    return 1
                fi
                ;; 
            pr|prs|pull-request|pull-requests)
                if is_true_ $(yq e "$proj_str.spec.services.prs"  $YML_PROJECTS); then
                    return 0
                else
                    error_ "Project '$proj_' does not allow pull-requests."
                    return 1
                fi
                ;; 
            comment|comments)
                if is_true_ $(yq e "$proj_str.spec.services.comments"  $YML_PROJECTS); then
                    return 0
                else
                    error_ "Project '$proj_' does not allow comments."
                    return 1
                fi
                ;; 
            *)
                error_ "proj_allow: '$serv_' is not a valid project service."
                return 1
                ;;
        esac
    fi 
}
