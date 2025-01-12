function get_(){
    case "$1" in
        projs|projects)
            yq e '.projects | keys | .[]'  "$YML_PROJECTS" ;;
        hooks)
            yq e '.hooks | keys | .[]'  "$YML_HOOKS" ;;
        pipes|pipelines)
            yq e '.pipelines | keys | .[]'  "$YML_PIPES" ;;
        provs|providers)
            yq e '.providers | keys | .[]'  "$YML_PROVIDERS" ;;
        *)
            error_ "invalid option for 'get_()' function" ;;
    esac    
}

function deps_ {
    for cmd in "${DEPS_[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            error_ "Missing dependency '$cmd'."
            return 1
        fi
    done
}

function input_ {
    local prompt="> "
    local extension="txt"
    local var="_input"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--prompt)
                prompt="$2"
                shift 2
                ;;
            -e|--ext|--extension)
                extension="$2"
                shift 2
                ;;
            -v|--var)
                var="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
    done

    local tmp_file
    tmp_file="$(mktemp --suffix=.$extension)"
    local input=""
    local cursor=0

    exec 3<&0
    exec < /dev/tty

    trap "" SIGINT SIGTSTP # do nothing with Ctrl+C (SIGINT) and Ctrl+Z (SIGTSTP)
    stty -echo
    echo -n "$prompt"

    while true; do
        IFS= read -r -s -n1 char
        case "$char" in
            $'\t'|$'\x09')
                stty echo
                if ! editor_ "$tmp_file"; then
                    rm -f "$tmp_file"
                    return 1
                fi
                input=$(<"$tmp_file")
                input=$(echo "$input" | jq -R -s .)
                rm -f "$tmp_file"
                cd - > /dev/null
                break
                ;;
            '')
                echo
                break
                ;;
            $'\x08'|$'\x7f')
                if (( cursor > 0 )); then
                    input="${input:0:cursor-1}${input:cursor}"
                    ((cursor--))
                    echo -ne "\b \b"
                fi
                ;;
            $'\x1b')
                read -r -s -n2 -t 0.1 rest
                if [[ -z "$rest" ]]; then
                    echo
                    stty echo
                    exec 0<&3 3<&-
                    rm -f "$tmp_file"
                    return 0
                fi
                if [[ "$rest" == "[C" ]]; then
                    if (( cursor < ${#input} )); then
                        ((cursor++))
                        echo -ne "\e[C"
                    fi
                elif [[ "$rest" == "[D" ]]; then
                    if (( cursor > 0 )); then
                        ((cursor--))
                        echo -ne "\e[D"
                    fi
                fi
                ;;
            $'\x04') # Ctrl+D
                echo
                stty echo
                exec 0<&3 3<&-
                rm -f "$tmp_file"
                return 0
                ;;
            *)
                input="${input:0:cursor}$char${input:cursor}"
                ((cursor++))
                echo -ne "\r${prompt}${input} \r${prompt}"
                for (( i=0; i<cursor; i++ )); do
                    echo -ne "\e[C"
                done
                ;;
        esac
    done

    stty echo
    exec 0<&3 3<&-
    declare -g "$var"="$input"
}

function is_hex_ {
    local color="$1"
    if [[ $color =~ ^[0-9A-Fa-f]{6}$ ]]; then
        return 0
    else
        return 1
    fi
}

function is_true_(){
    if [[ "${1^^}" == "TRUE" ]] ||
       [[ $1 -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

function is_null_(){
    if [[ -z "$1" ]] ||
       [[ "$1" == "null" ]]; then
        return 0
    else
        return 1
    fi
}

function is_error_(){
    error=$(echo "$1" | grep "error:")
    if [[ -n "$error" ]]; then
        echo -e "$1"
        return 0
    else
        return 1
    fi
}

function get_hex_() {
    local color_name="$1"
    case $color_name in
        r|red) echo "$LABEL_RED" ;;
        g|green) echo "$LABEL_GREEN" ;;
        b|blue) echo "$LABEL_BLUE" ;;
        y|yellow) echo "$LABEL_YELLOW" ;;
        c|cyan) echo "$LABEL_CYAN" ;;
        m|magenta) echo "$LABEL_MAGENTA" ;;
        w|white) echo "$LABEL_WHITE" ;;
        b|black) echo "$LABEL_BLACK" ;;
        *)
            if is_hex_ "$color_name"; then
                echo "$color_name"
            else
                error_ "Invalid color input. Use a named color or a valid HEX code." >&2
                return 1
            fi
            ;;
    esac
}

function hex_to_rgb_(){
    r_=$((16#${1:0:2}))
    g_=$((16#${1:2:2}))
    b_=$((16#${1:4:2}))
}

function bg_(){
    hex_to_rgb_ $1
    echo "\033[48;2;${r_};${g_};${b_}m"
}

function fg_(){
    hex_to_rgb_ $1
    echo "\033[38;2;${r_};${g_};${b_}m"
}

function is_date_(){
    if [[ -n "$1" ]] && 
       [[ ! $1 =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        error_ "Invalid date format. Use YYYY-MM-DD."
        return 1
    fi
    return 0
}

function date_(){
    if is_date_ $1; then
        echo "${1}T00:00:00Z"
    fi
}

function tab_ {
    local num_tabs="$1"
    local tabs=""
    local TAB_=${COMMA_TAB:-\\t}
    for ((i=0; i<num_tabs; i++)); do
        tabs+="$TAB_"
    done
    echo -ne "$tabs"
}

function item_ {
    secondary_ -c "$(tab_ 1)-" -n "$1"
}

function list_ {
    local elements=("$@")

    if [ ${#elements[@]} -eq 0 ]; then
        item_ "none"
    else
        for element in "${elements[@]}"; do
            item_ "$element"
        done
    fi
}

function fold_() {
    local line prefix
    while IFS= read -r line; do
        local indentation=$(echo "$line" | grep -o '^[[:space:]]*')
        if [[ "$line" =~ ^[[:space:]]*([0-9]+\.\ |[-*]\ )[[:space:]]* ]]; then
            prefix=$indentation$'\t'
        else
            prefix=$indentation
        fi
        echo "$line" | fold -s -w "$TEXT_WIDTH" | sed "2,\$s/^/$prefix/"
    done
}

function print_() {
    local temp=$(mktemp --suffix=".md")
    echo -e "$1" >> "$temp"

    if [[ "$PRINTER_" == "cat" ]]; then
        while IFS= read -r line; do
            echo "$line" | fold_
        done < "$temp" | sed 's/^/    | /'
    elif [[ "$PRINTER_" == "bat" ]]; then
        bat "$temp" --terminal-width=90 --wrap='auto' --style="numbers,grid"
    else
        error_ "PRINTER_ not defined."
        return 1
    fi
}


