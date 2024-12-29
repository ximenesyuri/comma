local dir_=${BASH_SOURCE%/*}
local dir_=${dir_%/*}
local main_=${dir_%/*}

lGLOBALS_="${main_}/yml/globals.yml"
local PROJECTS_="${main_}/yml/projects.yml"
local HOOKS_="${main_}/yml/hooks.yml"
local PIPES_="${main_}/yml/pipelines.yml"
local PROVIDERS_="${main_}/yml/providers.yml"

YML_GLOBALS=${G_YML_GLOBALS:-$GLOBALS_}
YML_PROJECTS=${G_YML_PROJECTS:-$PROJECTS_}
YML_HOOKS=${G_YML_HOOKS:-$HOOKS_}
YML_PIPES=${G_YML_PIPELINES:-$PIPES_}
YML_PROVIDERS=${G_YML_PROVIDERS:-$PROVIDERS_}

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
