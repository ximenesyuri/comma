function primary_() {
    local colored_text=()
    local normal_text=()
    local parsed_args=()

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -c|--colored)
                colored_text+=("$2")
                shift 2
                ;;
            -n|--not|--normal|--none)
                normal_text+=("$2")
                shift 2
                ;;
            *)
                parsed_args+=("$1")
                shift
                ;;
        esac
    done

    if [ ${#colored_text[@]} -eq 0 ] && [ ${#normal_text[@]} -eq 0 ]; then
        echo -e "${PRIMARY}${parsed_args[*]}${RESET}"
    else
        echo -e "${PRIMARY}${colored_text[*]}${RESET} ${normal_text[*]}"
    fi
}

function secondary_() {
    local colored_text=()
    local normal_text=()
    local parsed_args=()

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -c|--colored)
                colored_text+=("$2")
                shift 2
                ;;
            -n|--not|--normal|--none)
                normal_text+=("$2")
                shift 2
                ;;
            *)
                parsed_args+=("$1")
                shift
                ;;
        esac
    done

    if [ ${#colored_text[@]} -eq 0 ] && [ ${#normal_text[@]} -eq 0 ]; then
        echo -e "${SECONDARY}${parsed_args[*]}${RESET}"
    else
        echo -e "${SECONDARY}${colored_text[*]}${RESET} ${normal_text[*]}"
    fi
}

function error_() {
    echo -e "${ERROR}error:${RESET}" "$@"  
}

function done_() {
    echo -e "${DONE}done:${RESET}" "$@"  
}

function info_() {
    echo -e "${INFO}info:${RESET}" "$@"  
}

function warn_() {
    echo -e "${WARN}warn:${RESET}" "$@"
}

function line_(){
    secondary_ "$LINE"
}

function entry_(){
    if [[ -n "$2" ]]; then
        printf "${PRIMARY}%-*s${RESET} %s\n" $LABEL_WIDTH "$1:" "$2"
    else
        error_ "entr_: Missing arguments."
    fi
}

