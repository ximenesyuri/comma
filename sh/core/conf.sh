local dir_=${BASH_SOURCE%/*}
local dir_=${dir_%/*}
local main_=${dir_%/*}

GLOBALS_="${main_}/yml/globals.yml"
local PROJECTS_="${main_}/yml/projects.yml"
local HOOKS_="${main_}/yml/hooks.yml"
local PIPES_="${main_}/yml/pipelines.yml"
local PROVIDERS_="${main_}/yml/providers.yml"

YML_GLOBALS=${COMMA_YML_GLOBALS:-$GLOBALS_}
YML_PROJECTS=${COMMA_YML_PROJECTS:-$PROJECTS_}
YML_HOOKS=${COMMA_YML_HOOKS:-$HOOKS_}
YML_PIPES=${COMMA_YML_PIPELINES:-$PIPES_}
YML_PROVIDERS=${COMMA_YML_PROVIDERS:-$PROVIDERS_}

editor_=$(yq e '.globals.editor // ""' $YML_GLOBALS)
browser_=$(yq e '.globals.browser // ""' $YML_GLOBALS)

EDITOR_="${COMMA_EDITOR:-$(echo $editor_ || $EDITOR || vim)}"
BROWSER_="${COMMA_BROWSER:-$(echo $browser_ || $BROWSER || firefox)}"

function load_ {
    local key=$2
    if [[ -z "$key" ]]; then
        echo "ERROR: missing key in 'load_()' function."
        return 1
    fi
    case "$1" in
        global|globals)
            yq e ".${key}" "$YML_GLOBALS" ;;
        prj|projs|projects)
            yq e ".${key}" "$YML_PROJECTS" ;;
        hook|hooks)
            yq e ".${key}" "$YML_HOOKS" ;;
        pipe|pipes|pipeline|pipelines)
            yq e ".${key}" "$YML_PIPES" ;;
        prov|provider|providers)
            yq e ".${key}" "$YML_PROVIDERS" ;;
        *)
            echo "ERROR: invalid option for 'load_()' function" ;;
    esac
}

function get_(){
    case "$1" in
        global|globals)
            yq e '.globals | keys | .[]' "$YML_GLOBALS" ;;
        prj|projs|projects)
            yq e '.projects | keys | .[]'  "$YML_PROJECTS" ;;
        hook|hooks)
            yq e '.hooks | keys | .[]'  "$YML_HOOKS" ;;
        pipe|pipes|pipeline|pipelines)
            yq e '.pipelines | keys | .[]'  "$YML_PIPES" ;;
        prov|provider|providers)
            yq e '.providers | keys | .[]'  "$YML_PROVIDERS" ;;
        *)
            echo "ERROR: invalid option for 'get_()' function" ;;
    esac    
}
