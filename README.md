# About

`comma`  is a universal CLI tool to manage git providers, as [Github](https://github.com), [Gitlab](https://gitlab.com), [Gitea](https://gitea.com) and [Bitbucket](https://bitbucket.org/product/), made with `bash` and configurable in `yaml`, to work as:
1. an intuitive and lightweight replacement for the core functionalities of [gh](https://github.com/cli/cli), [glab](https://gitlab.com/gitlab-org/cli), [tea](https://gitea.com/gitea/tea), and so on
2. a custom `bash` pipelines manager, allowing to work, for example, as a git hooks or CI/CD tool.

# Features

- **Structure**:
    1. Unified project management
    2. Project focused 
    4. Multiple configuration levels:
        1. environment variables
        2. global configuration file (`.yml`)
        3. project-level configuration file (`.yml`)
        4. repository configuration file (`.yml`)
    5. Intuitive and interactive, with `fzf` interface
    6. User friendly with multiples command aliases
    7. Completion script
    8. Lightweight with minimal dependencies
    9. Easy to install: just plug and play
- **Management**:
    1. Execute basic git commands remotely
    2. Handle issues, labels, milestones, PRs/MRs, and so on, in the different platforms, as:
        1. [Github](https://github.com)
        2. [Gitlab](https://gitlab.com) (including self-hosted instances)
        3. [Gitea](https://gitea.com) (including instances, as [Codeberg](https://codeberg.org/) or self-hosted)
        4. [Bitbucket](https://bitbucket.org/product/)
    3. Define global or per project `bash` pipelines
    4. Execute pipelines remotely

# Dependencies

- **Mandatory**:
    1. `bash`: the interpreter
    2. [fzf](https://github.com/junegunn/fzf): to provide nice user experience
    3. [jq](https://github.com/jqlang/jq): to manage API calls
    4. [yq](https://github.com/mikefarah/yq): to handle configuration files
- **Optional**:
    1. `curl`: to install dependencies with the `install` script (see below)
    2. `ssh`: to connect to remotes 

# Install

- Manually:
    1. install the dependencies
    2. clone the repository `ximenesyuri/comma`
    3. source the `comma` script in your `.bashrc` file
```bash
    git clone https://github.com/ximenesyuri/comma /your/favorite/location/comma && \
        echo "source /your/favorite/location/comma/comma" >> $HOME/.bashrc
```
- Script:
    1. clone the repository
    2. execute the `install` script
```bash
    git clone https://github.com/ximenesyuri/comma /your/favorite/location/comma && \
        sudo bash /your/favorite/location/comma/install
```

> The missing dependencies will be automatically installed with the `install` script.

# Usage

See [doc/usage](./doc/usage.md).

# Configuration

See [doc/conf](./doc/conf.md).

# See also

Other tools made with `bash` and `yaml` configurable:

1. [dot](https://github.com/ximenesyuri/dot): a universal terminal utility
2. [web](https://github.com/ximenesyuri/web): a terminal tool to manage bookmarks and search across (software development related) search engines 

