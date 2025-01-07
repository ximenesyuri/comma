CATS_=($(get_ "cats"))
    
    if [[ -n "${COMMA_DEFAULT_CAT}" ]]; then
        if [[ ${CATS_[@]} =~ "${COMMA_DEFAULT_CAT}" ]]; then
            local DEFAULT_CAT=${COMMA_DEFAULT_CAT}
        else
            error_ "Error in env 'COMMA_DEFAULT_OBJECT': '$COMMA_DEFAULT_OBJECT' is not a valid catalog."
            return 1
        fi 
    fi
