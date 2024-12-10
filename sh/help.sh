function g_help {
        echo "Usage:
    g [command]
    g [project] [general_command] [argument]
    g [project] [topic] [action]

General Commands:
    new                  Add a new project to the todo list
    rm                   Remove a project from the todo list
    ls                   List all projects
    help, --help         Show this help message

Project Topics:
    issue/issues/i       Control issues
    label/labels         Control labels
    pr/mr                Control PRs or MRs

Actions for a topic:
    new                  Create a new item (issue/label/pr)
    close [filter]       Close an item with specified ID
    reopen [filter]      Reopen a closed item with specified ID
    ls                   List items
    edit                 Edit a selected item (title, description, labels)

General project commands [project] [general_command] [argument]:
    clone, c             Clone a repository
    push, p, ps          Execute the "push pipeline"
    pull, pl             Execute the "pull pipeline"
    delete, D            Delete the repository
    "
    }
