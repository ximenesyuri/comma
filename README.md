# About

`g`  is a universal CLI tool to manage git providers, as Github, Gitlab and Gitea, made with `bash`, `yaml` and `fzf`, to work as a lightweight replacement for the core functionalities of [gh](https://github.com/cli/cli), [glab](https://gitlab.com/gitlab-org/cli), [tea](https://gitea.com/gitea/tea), and so on. It also allows to create custom `bash` pipelines for git projects, allowing to work, for example, as a git hooks tool.

# Features

1. Unified project management
2. Easily configurable with `yaml`
3. intuitive `fzf` interface
4. Project-oriented with centralized configuration
5. Project level and global level settings
6. Handle issues, labels, milestones, PRs/MRs, and so on
7. Create, clone and delete repositories
8. Define global or per project `bash` pipelines
9. User friendly with multiples command aliases
10. Completion script

# Dependencies

1. `bash`: i.e, a UNIX-based operating system
2. [fzf](https://github.com/junegunn/fzf)
3. [jq](https://github.com/jqlang/jq)
4. [yq](https://github.com/mikefarah/yq)

> The missing dependencies could be installed with the `install.sh` script.

# Usage

```
USAGE
    g [action] [object] [argument]
    g [default_object] [service/command] [action]

ACTIONS
    l, ls, list .................................. list something
    i, info ...................................... get info about something
    n, new, c, create ............................ creates something
    r, rm, d, del, delete ........................ delete something
    e, ed, edit .................................. edit something

OBJECTS
    p, prj, proj, project(s)...................... projects
    P, pv, prv, prov, provider(s)................. providers
    pp, pip, pipe, pipeline(s) ................... pipelines
    h, hk, hook(s) ............................... hooks

SERVICES[proj]
    i, iss, issue(s) ............................. issues
    l, lbl, label(s) ............................. labels
    m, mil, mile, milestone(s) ................... milestones
    pr, mr, pull-request(s), merge-request(s) .... pull requests and merge-requests
```


