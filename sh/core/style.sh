# ANSI COLORS
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
RESET="\033[0m"

PRIMARY=${COMMA_COLOR_PRIMARY:-$BLUE}
SECONDARY=${COMMA_COLOR_SECONDARY:-$MAGENTA}
ERROR=${COMMA_COLOR_ERROR:-$RED}
DONE=${COMMA_COLOR_DONE:-$GREEN}
INFO=${COMMA_COLOR_INFO:-$MAGENTA}
WARN=${COMMA_COLOR_WARN:-$WARN}

# LABELS COLORS
LABEL_RED_="ff0000"
LABEL_GREEN_="00ff00"
LABEL_BLUE_="0000ff"
LABEL_YELLOW_="ffff00"
LABEL_CYAN_="00ffff"
LABEL_MAGENTA_="ff00ff"
LABEL_WHITE_="ffffff"
LABEL_BLACK_="000000"

LABEL_RED="${COMMA_LABEL_COLOR_RED:-$LABEL_RED_}"
LABEL_GREEN="${COMMA_LABEL_COLOR_GREEN:-$LABEL_GREEN_}"
LABEL_BLUE="${COMMA_LABEL_COLOR_BLUE:-$LABEL_BLUE_}"
LABEL_YELLOW="${COMMA_LABEL_COLOR_YELLOW:-$LABEL_YELLOW_}"
LABEL_CYAN="${COMMA_LABEL_COLOR_CYAN:-$LABEL_CYAN_}"
LABEL_MAGENTA="${COMMA_LABEL_COLOR_MAGENTA:-$LABEL_MAGENTA_}"
LABEL_WHITE="${COMMA_LABEL_COLOR_WHITE:-$LABEL_WHITE_}"
LABEL_BLACK="${COMMA_LABEL_COLOR_BLACK:-$LABEL_BLACK_}"

LABEL_DEFAULT_COLOR="${COMMA_LABEL_DEFAULT_COLOR:-$LABEL_WHITE}"

# TEXT STRUCTURE
TEXT_WIDTH=${COMMA_TEXT_WIDTH:-80}
LABEL_WIDTH=${COMMA_LABEL_WIDTH:-12}
FZF_GEOMETRY_="--height=30% --layout=reverse"
FZF_GEOMETRY="${COMMA_FZF_GEOMETRY:-$FZF_GEOMETRY_}"

LINE_="-----------------------"
LINE=${COMMA_LINE_STRING:-$LINE_}
