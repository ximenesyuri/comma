function proj_(){

    declare -a SERV_=(git dot issue label pr miles hook pipe)

    declare -A SERV_ALIASES=(
        [dot]="."
        [git]="g"
        [issue]="i issues"
        [label]="l labels"
        [pr]="prs mr mrs pull-request pull-requests merge-request merge-requests"
        [miles]="m mil milestone milestones"
        [hook]="h hooks"
        [pipe]="pp pip pipeline pipelines"
    )

    if [[ -z "$1" ]]; then
        help_proj
        return 0
    fi

    declare -a projs
    projs=($(get_ projs))

    local match_proj=""
    for proj in "${projs[@]}"; do
        if [[ "$proj" == "$1" ]]; then
            match_proj="true" 
        fi
    done
    if [[ "$match_proj" != "true"  ]]; then
        error_ "'$1' is not a valid project."
        info_ "Try 'comma cat ls proj' to see the available projects." 
        return 1
    fi

    local PROJ_DIR=${BASH_SOURCE%/*}
    function PROJ_DEPS() {
        source $PROJ_DIR/utils/utils.sh
        source $PROJ_DIR/utils/method.sh
        source $PROJ_DIR/utils/endpoint.sh
        source $PROJ_DIR/utils/payload.sh
    }

    for serv in ${SERV_[@]}; do
        eval "SERV_${serv^^}=$PROJ_DIR/servs/$serv.sh"
    done

    local match_serv=''
    for serv in ${SERV_[@]}; do
        declare -a aliases=(${SERV_ALIASES[$serv]})
        match_serv="true"
        if [[ -z "$2" ]]; then
            local path=$(yq e ".local.${1}.spec.path" "$YML_LOCAL" | envsubst)
            "$MAIN_" "$path"
            return 1
        elif [[ "${aliases[@]}" =~ "$2" ]] ||
             [[ "$2" == "$serv" ]]; then
            serv_=SERV_${serv^^}
            source ${!serv_}
            "${serv}_" "$1" "${@:3}"
            if [[ ! "$?" == "0" ]]; then
                return 1
            fi
            return 0
        fi
    done
    if [[ "$match_serv" != "true" ]]; then
        error_ "'$2' is not a valid service for the object 'proj'."
        return 1
    fi
}
