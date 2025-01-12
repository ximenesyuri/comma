local dir_=${BASH_SOURCE%/*}
local dir_=${dir_%/*}
local main_=${dir_%/*}
 
declare -a PROVS_=(github gitlab gitea bitbucket)
declare -A API_
for prov_ in ${PROVS_[@]}; do
    API_[$prov_]="${main_}/src/yml/provs/${prov_}.yml"
done

local YML_=$main_/yml
local YML_CONF=$YML_/conf.yml
local YML_LOCAL=$YML_/local.yml

local editor_=$(yq e '.conf.tools.editor // ""' $YML_CONF)
local browser_=$(yq e '.conf.tools.browser // ""' $YML_CONF)
local pager_=$(yq e '.conf.tools.pager // ""' $YML_CONF)
local dot_=$(yq e '.conf.commands.dot // ""' $YML_CONF)
local main_=$(yq e '.conf.commands.main // ""' $YML_CONF)
local theme_=$(yq e '.conf.general.theme // ""' $YML_CONF)

declare -a tools_=(editor browser pager printer)
declare -A default_tools=(
    [editor]="vim"
    [browser]="firefox"
    [pager]="less"
    [printer]="cat"
)

for tool in ${tools_[@]}; do
    TOOL=${tool^^}
    TOOL_=${TOOL}_
    TOOL_ENV="COMMA_TOOLS_${TOOL}"
    _tool=${tool}_
    default_tool=${default_tools[$tool]}
    if [[ -n "${!TOOL_ENV}" ]]; then
        eval "${TOOL_}=${!TOOL_ENV}"
    elif [[ -n "${!_tool}" ]]; then
        eval "${TOOL_}=${!_tool}"
    elif [[ -n "${!TOOL}" ]]; then
        eval "${TOOL_}=${!TOOL}"
    elif command -v "${default_tool}" > /dev/null 2>&1; then
        eval "${TOOL_}=${default_tool}"
    fi
done

declare -a commands_=(main dot)
declare -A default_commands=(
    [main]="cd"
    [dot]="cd"
)

for cmd in ${commands_[@]}; do
    CMD=${cmd^^}
    CMD_=${CMD}_
    CMD_ENV="COMMA_COMMANDS_${CMD}"
    _cmd=${cmd}_
    default_cmd=${default_commands[$cmd]}

    if [[ -n "${!CMD_ENV}" ]]; then
        eval "${CMD_}=${!CMD_ENV}"
    elif [[ -n "${!_cmd}" ]]; then
        eval "${CMD_}=${!_cmd}" 
    elif [[ -c "${default_cmd}" ]]; then
        eval "${TOOL_}=${default_cmd}"
    fi
done

declare -a general_=(theme)
declare -A default_general=(
    [theme]="basic"
)

for gen in ${general_[@]}; do
    GEN=${gen^^}
    GEN_=${GEN}_
    GEN_ENV="COMMA_GENERAL_${GEN}"
    _gen=${gen}_
    default_gen=${default_general[$gen]}

    if [[ -n "${!GEN_ENV}" ]]; then
        eval "${GEN_}=${!GEN_ENV}"
    elif [[ -n "${!_gen}" ]]; then
        eval "${GEN_}=${!_gen}"
    elif [[ -c "${default_gen}" ]]; then
        eval "${GEN_}=${default_gen}"
    fi
done

CATS_=($(yq e '.conf.catalogs | keys | .[]' $YML_CONF))
PROJS_=($(yq e '.local | keys | .[]' $YML_LOCAL))
CAT_PROJS=($(yq e '.local | keys | .[]' $YML_LOCAL))

default_cats=($(yq e '.conf.catalogs | to_entries | map(select(.value.default == true)) | .[].key' $YML_CONF))
if [[ -n "${default_cats[0]}" ]]; then
    if [[ -n "${default_cats[1]}" ]]; then
        error_ "Multiples catalogs with 'default:true'."
        info_ "Default catalogs: ${default_cats[*]}"
        return 1
    else
        CAT_="${default_cats[0]}"
        local CAT_PATH="$(yq e ".conf.catalogs.$CAT_.path // \"\"" $YML_CONF | envsubst)"
        if [[ -n "$CAT_PATH" ]]; then
            YML_CAT=$CAT_PATH
            YML_PROJECTS=$YML_CAT/projects.yml
            YML_PROVIDERS=$YML_CAT/providers.yml
            YML_HOOKS=$YML_CAT/hooks.yml
            YML_PIPES=$YML_CAT/pipes.yml
            YML_TEAMS=$YML_CAT/teams.yml
            YML_RESOURCES=$YML_CAT/resources.yml
        else
            error_ "Path not set for the default catalog '$CAT_'."
            info_ "See '.conf.catalogs.$CAT_.path' in '$YML_CONF'."
            return 1
        fi
    fi
fi
