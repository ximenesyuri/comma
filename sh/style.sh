RED="\033[31m"
GREEN="\033[32m"
BLUE="\033[34m"
MAGENTA="\033[35m"
RESET="\033[0m"

PRIMARY=${G_COLOR_PRIMARY:-$BLUE}
SECONDARY=${G_COLOR_SECONDARY:-$MAGENTA}
ERROR=${G_COLOR_ERROR:-$RED}
DONE=${G_COLOR_DONE:-$GREEN}
INFO=${G_COLOR_INFO:-$MAGENTA}

WIDTH=${G_WIDTH:-12}
fzf_geometry_="--height=20% --layout=reverse"
FZF_GEOMETRY="${G_FZF_GEOMETRY:-$fzf_geometry_}"

label_default_color_="ffffff"
LABEL_DEFAULT_COLOR="${G_LABEL_DEFAULT_COLOR:-$label_default_color_}"

function primary_(){
    echo -e "${PRIMARY}$1${RESET}"
}

function secondary_(){
    echo -e "${SECONDARY}$1${RESET}"
}

function line_(){
    secondary_ "-----------------------"
}

function error_(){
    echo -e "${ERROR}error:${RESET} $1"
}

function done_(){
    echo -e "${DONE}done:${RESET} $1"
}

function info_(){
    echo -e "${INFO}info:${RESET} $1"
}
