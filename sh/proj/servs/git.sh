function git_ {
    local proj="$1"
    local action="$2"
    local param="$3"
    local proj_path
    proj_path=$(yq e ".local.$proj.spec.path" "$YML_LOCAL" | envsubst)

    if [[ -z "$proj_path" || "$proj_path" == "null" ]]; then
        error_ "Project path not set for '$proj'."
        info_ "Check '.local.$proj.spec.path' in '$YML_PROJECTS'."
        return 1
    fi

    pushd "$proj_path" > /dev/null

    case "$action" in
        a|add)
            git_add "$proj"
            ;;
        c|commit)
            git_commit "$proj" "$param"
            ;;
        p|push)
            git_push "$param" "$proj"
            ;;
        P|pull)
            git_pull "$param" "$proj"
            ;;
        A|amend)
            git_amend
            ;;
        l|log|ls)
            git_log "$proj"
            ;;
        d|diff)
            git_diff
            ;;
        *)
            error_ "Unsupported git action: $action."
            popd > /dev/null
            return 1
            ;;
    esac

    popd > /dev/null
    return 0
}


function git_add {
    git add .
    if [[ ! "$?" == "0" ]]; then
        return 1
    fi
    done_ "Changes added to stage in proj '$1'."
}

function git_commit {
    local proj="$1"
    shift
    local message="$@"
    
    if [[ -z "$message" ]]; then
        primary_ "Enter commit message:"
        input_ -v  message
        if [[ -z "$message" ]]; then
            error_ "Commit message required."
            return 1
        fi
    fi
    git commit -m "$message"
    if [[ ! "$?" == "0" ]]; then
        return 1
    fi
    done_ "Commit has been made in proj '$proj'."
}

function git_push {
    local branch="$1"
    local proj="$2"

    if [[ -z "$branch" ]]; then
        error_ "Branch name required."
        return 1
    fi
    git push origin "$branch"
    if [[ ! "$?" == "0" ]]; then
        return 1
    fi
    done_ "Pushed branch '$branch' to origin in proj '$proj'."
}

function git_pull {
    local branch="$1"
    local proj="$2"

    if [[ -z "$branch" ]]; then
        error_ "Branch name required."
        return 1
    fi
    git pull origin "$branch"
    if [[ ! "$?" == "0" ]]; then
        return 1
    fi
    done_ "Pulled origin to branch '$branch' in proj '$proj'."
}

function git_amend {
    local commit_id
    commit_id=$(git log --oneline | fzf $FZF_GEOMETRY)
    
    if [[ -n "$commit_id" ]]; then
        primary_ "New message:"
        input_ -v new_message
        git commit --amend -m "$new_message" --no-edit
        if [[ ! "$?" == "0" ]]; then
            return 1
        fi
        done_ "The commit has been amended."
    else
        error_ "No commit selected."
    fi
}

function git_log {
    local proj="$1"
    
    local commit
    commit=$(git log --oneline | fzf $FZF_GEOMETRY | awk '{print $1}')
    if [ -z "$commit" ]; then
        error_ "No commit selected."
        return 1
    fi

    local commit_info
    commit_info=$(git show --format="%H%n%an%n%aI%n" "$commit")

    local commit_hash
    commit_hash=$(echo "$commit_info" | sed -n '1p')

    local author
    author=$(echo "$commit_info" | sed -n '2p')

    local timestamp
    timestamp=$(echo "$commit_info" | sed -n '3p')

    local repo
    repo=$(yq e ".projects.$proj.server.spec.repo" "$YML_PROJECTS" | envsubst)

    local provider
    provider=$(yq e ".projects.$proj.server.spec.provider" "$YML_PROJECTS" | envsubst)

    local pushed
    pushed=$(git branch --contains "$commit" -r)
    local pushed_flag
    [ -z "$pushed" ] && pushed_flag=false || pushed_flag=true

    local commit_url="Not available"
    if [ "$pushed_flag" = true ]; then
        case $provider in
            github) commit_url="https://github.com/$repo/commit/$commit_hash" ;;
            gitlab) commit_url="https://gitlab.com/$repo/-/commit/$commit_hash" ;;
            bitbucket) commit_url="https://bitbucket.org/$repo/commits/$commit_hash" ;;
            gitea) commit_url="https://gitea.com/$repo/commit/$commit_hash" ;;
            *)
                commit_url="Not available"
                ;;
        esac
    fi

    local modified_stats
    modified_stats=$(git show --name-status "$commit")

    local created_files
    created_files=$(echo "$modified_stats" | awk '$1 == "A" { print $2 }')
    local deleted_files
    deleted_files=$(echo "$modified_stats" | awk '$1 == "D" { print $2 }')
    local modified_files
    modified_files=$(echo "$modified_stats" | awk '$1 == "M" { print $2 }')

    local files_modified
    files_modified=$(echo "$created_files" "$deleted_files" "$modified_files" | wc -w)

    entry_ "Project" "$proj"
    entry_ "Repo" "$repo"
    line_
    entry_ "Hash" "$commit_hash"
    entry_ "Time" "$timestamp"
    entry_ "Author" "$author"
    entry_ "Url" "$commit_url"
    entry_ "Pushed" "$pushed_flag"
    entry_ "Modif" "$files_modified"
    line_

    if [ -n "$created_files" ]; then
        echo "Created:"
        echo "$created_files" | nl -w 4 -s '. '
    else
        echo "Created: none"
    fi
    line_

    if [ -n "$deleted_files" ]; then
        echo "Deleted:"
        echo "$deleted_files" | nl -w 4 -s '. '
    else
        echo "Deleted: none"
    fi
    line_

    echo "Modified:"
    if [ -n "$modified_files" ]; then
        echo "$modified_files" | while read -r line; do
            added=$(git show "$commit" -- "$line" | grep -c '^+[^+]')
            removed=$(git show "$commit" -- "$line" | grep -c '^-[^-]')
            echo "$line ($removed lines removed) ($added lines added)"
        done | nl -w 4 -s '. '
    else
        echo "   None"
    fi
}

function git_diff {
    local commit=$(git log --oneline | fzf $FZF_GEOMETRY)
    
    if [[ -n "$commit" ]]; then
        local commit_hash
        commit_hash=$(echo "$commit" | awk '{print $1}')
        local modified_file
        modified_file=$(git diff-tree --no-commit-id --name-only -r "$commit_hash" | fzf $FZF_GEOMETRY)

        if [[ -n "$modified_file" ]]; then
            case "${PAGER_}" in
                "")
                    git config core.pager "less --tabs=4 -RF"
                    git diff "$commit_hash":"$modified_file" "$modified_file"
                    ;;
                vim|vimdiff)
                    tmpfile=$(mktemp --suffix=".$(echo $modified_file | sed -E 's|.*\.([^./]+)$|\1|')")
                    git show "$commit_hash":"$modified_file" > "$tmpfile"
                    vimdiff "$tmpfile" "$modified_file" -c "set conceallevel=0" -c "set nofoldenable"
                    rm "$tmpfile"
                    ;;
                diff-so-fancy|fancy)
                    git config core.pager "diff-so-fancy | less --tabs=4 -RF"
                    git config interactive.diffFilter "diff-so-fancy --patch"
                    git diff "$commit_hash":"$modified_file" "$modified_file"
                    ;;
                diff-highlight|highlight)
                    git config core.pager "diff-highlight | less --tabs=4 -RF"
                    git diff "$commit_hash":"$modified_file" "$modified_file"
                    ;;
                delta)
                    git config core.pager delta
                    git config interactive.diffFilter 'delta --color-only'
                    git config delta.navigate true
                    git config delta.side-by-side true
                    git diff "$commit_hash":"$modified_file" "$modified_file"
                    ;;
                *)
                    git config core.pager "${PAGER_}"
                    git diff "$commit_hash":"$modified_file" "$modified_file"
                    ;;
            esac
        else
            error_ "No file selected."
        fi
    else
        error_ "No commit selected."
    fi
}
