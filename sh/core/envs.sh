local dir_=${BASH_SOURCE%/*}
local dir_=${dir_%/*}
local main_=${dir_%/*}

YML_API=${main_}/src/yml/api.yml

local yml_=$main_/yml
local yml_usr=$yml_/usr
local yml_obj=$yml_/obj

local YML_=${COMMA_YML:-$yml_}
local YML_USR=${COMMA_YML_USR:-$yml_usr}
local YML_OBJ=${COMMA_YML_USR:-$yml_obj}

YML_CONF="$YML_USR/conf.yml"
YML_THEME="$YML_USR/theme.yml"

YML_PROJECTS=$YML_OBJ/projects.yml
YML_PROVIDERS=$YML_OBJ/providers.yml
YML_HOOKS=$YML_OBJ/hooks.yml
YML_PIPES=$YML_OBJ/pipes.yml
YML_TEAMS=$YML_OBJ/teams.yml
YML_RESOURCES=$YML_OBJ/resources.yml

editor_=$(yq e '.conf.editor // ""' $YML_CONF)
browser_=$(yq e '.conf.browser // ""' $YML_CONF)
pager_=$(yq e '.conf.pager // ""' $YML_CONF)
dot_=$(yq e '.conf.dot // ""' $YML_CONF)
main_=$(yq e '.conf.main // ""' $YML_CONF)
theme_=$(yq e '.conf.theme // ""' $YML_CONF)

EDITOR_="$(echo "$editor_" || echo "$COMMA_EDITOR" || echo $EDITOR || echo "vim")"
BROWSER_="$(echo "$browser_" || echo "$COMMA_BROWSER" || echo "$BROWSER" || echo "firefox")"
PAGER_="$(echo "$pager_" || echo "$COMMA_PAGER" || echo "$PAGER")"
DOT_="$(echo "$dot_" || echo "$COMMA_DOT" || echo "cd")"
MAIN_="$(echo "$main_" || echo "$COMMA_MAIN")"
THEME_="$(echo "$main_" || echo "$COMMA_THEME" || echo "default")"
