local dir_=${BASH_SOURCE%/*}
local dir_=${dir_%/*}
local main_=${dir_%/*}

YML_API=${main_}/src/yml/api.yml

local yml_=$main_/yml
local yml_usr=$conf_/usr
local yml_obj=$conf_/obj

local YML_=${COMMA_YML:$conf_}
local YML_USR=${COMMA_YML_USR:$conf_usr}
local YML_OBJ=${COMMA_YML_USR:$conf_obj}

YML_CONF="$YML_USR/settings.yml"
YML_THEME="$YML_USR/theme.yml"

YML_PROJECTS=$YML_OBJ/projects.yml
YML_PROVIDERS=$YML_OBJ/providers.yml
YML_HOOKS=$YML_OBJ/hooks.yml
YML_PIPES=$YML_OBJ/pipes.yml
YML_TEAMS=$YML_OBJ/teams.yml
YML_RESOURCES=$YML_OBJ/resources.yml

editor_=$(yq e '.settings.editor // ""' $YML_CONF)
browser_=$(yq e '.settings.browser // ""' $YML_CONF)
pager_=$(yq e '.settings.pager // ""' $YML_CONF)
dot_=$(yq e '.settings.dot // ""' $YML_CONF)
main_=$(yq e '.settings.main // ""' $YML_CONF)
theme_=$(yq e '.settings.theme // ""' $YML_CONF)

EDITOR_="$(echo "$editor_" || echo "$COMMA_EDITOR" || echo $EDITOR || echo "vim")"
BROWSER_="$(echo "$browser_" || echo "$COMMA_BROWSER" || echo "$BROWSER" || echo "firefox")"
PAGER_="$(echo "$pager_" || echo "$COMMA_PAGER" || echo "$PAGER")"
DOT_="$(echo "$dot_" || echo "$COMMA_DOT" || echo "cd")"
MAIN_="$(echo "$main_" || echo "$COMMA_MAIN" || echo "cd")"
THEME_="$(echo "$main_" || echo "$COMMA_THEME" || echo "default")"
