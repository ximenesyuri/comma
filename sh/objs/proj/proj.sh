function proj_(){

    declare -a SERV_=(dot issue label pr miles prov hook pipe)

    declare -A SERV_ALIASES=(
        [dot]="."
        [issue]="i issues"
        [label]="l labels"
        [pr]="p prs mr mrs pull-request pull-requests merge-request merge-requests"
        [miles]="m mil milestone milestones"
        [prov]="pv provider providers"
        [hook]="h hooks"
        [pipe]="pp pip pipeline pipelines"
    )

    for serv in ${SERV_[@]}; do
        eval "SERV_${serv^^}=${BASH_SOURCE%/*}/servs/$serv.sh"
    done

    local match_serv=''
    for serv in ${SERV_[@]}; do
        declare -a aliases=(${SERV_ALIASES[$serv]})
        match_serv=0
        if [[ -z "$2" ]]; then
            help_proj
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
    if [[ $match_serv -eq 0 ]]; then
        error_ "'$2' is not a valid service for the object 'proj'."
        return 1
    fi
}
