function g_load_configuration {
    local key=$1
    yq e ".${key}" "$G_CONF"
}

BROWSER_CMD=$(g_load_configuration "globals.browser")
EDITOR_CMD=$(g_load_configuration "globals.editor")

function g_get_projects {
    yq e '.projects | keys | .[]' "$G_CONF"
}

function g_get_project_info {
    local project_name=$1
    yq e ".projects.${project_name}" "$G_CONF"
}



