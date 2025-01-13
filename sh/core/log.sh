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
        echo -e "${COLOR_PRIMARY}${parsed_args[*]}${COLOR_RESET}"
    else
        echo -e "${COLOR_PRIMARY}${colored_text[*]}${COLOR_RESET} ${normal_text[*]}"
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
        echo -e "${COLOR_SECONDARY}${parsed_args[*]}${COLOR_RESET}"
    else
        echo -e "${COLOR_SECONDARY}${colored_text[*]}${COLOR_RESET} ${normal_text[*]}"
    fi
}

function error_() {
    echo -e "${COLOR_ERROR}${TEXT_ERROR}:${COLOR_RESET}" "$@"  
}

function done_() {
    echo -e "${COLOR_DONE}${TEXT_DONE}:${COLOR_RESET}" "$@"  
}

function info_() {
    echo -e "${COLOR_INFO}${TEXT_INFO}:${COLOR_RESET}" "$@"  
}

function warn_() {
    echo -e "${COLOR_WARN}${TEXT_WARN}:${COLOR_RESET}" "$@"
}

function debug_() {
    echo -e "${COLOR_DEBUG}${TEXT_DEBUG}:${COLOR_RESET}" "$@"
}

function line_(){
    echo -e "${COLOR_LINE}${TEXT_LINE}${COLOR_RESET}"
}

function double_(){
    echo -e "${COLOR_DOUBLE_LINE}${TEXT_DOUBLE_LINE}${COLOR_RESET}"
}

function entry_(){
    if [[ -n "$2" ]]; then
        printf "${COLOR_ENTRY}%-*s${COLOR_RESET} %s\n" ${WIDTH_ENTRY} "$1:" "$2"
    else
        error_ "entry_: Missing arguments."
    fi
}

