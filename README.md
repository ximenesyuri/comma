# About

`g`  is a universal CLI tool to manage git providers, as Github, Gitlab and Gitea, made with `bash`, `yaml` and `fzf`, to work as a lightweight replacement for the core functionalities of [gh](https://github.com/cli/cli), [glab](https://gitlab.com/gitlab-org/cli), [tea](https://gitea.com/gitea/tea), and so on. It also allows to create custom `bash` pipelines for git projects, allowing to work, for example, as a git hooks tool.

# Features

1. Unified management
2. Easily configurable with `yaml`
3. intuitive `fzf` interface
4. Project oriented with centralized configuration
5. Handle issues, labels, PRs/MRs, and so on
6. Create, clone and delete repositories
7. Define global or per project `bash` pipelines

# Dependencies

1. `bash`, i.e, a UNIX-based operating system
2. [fzf](https://github.com/junegunn/fzf)
3. [jq](https://github.com/jqlang/jq)
4. [yq](https://github.com/mikefarah/yq)

> The missing dependencies could be installed with the `install.sh` script.

# Usage

```
USAGE
    g [core_command] [argument]
    g [project_name] [project_command] [argument]
```


