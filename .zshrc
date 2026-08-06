export PATH
autoload -U colors && colors
export TERM="xterm-256color"

eval "$(starship init zsh)"
# Set up fzf key bindings and fuzzy completion
# Ctrl-T のファイル検索では、依存物やキャッシュの配下を探索しない
export FZF_CTRL_T_COMMAND='command find -L . -mindepth 1 \( -name .git -o -name __pycache__ -o -name .terraform -o -name .ruff_cache -o -name .venv \) -prune -o \( -type d -o -type f -o -type l \) -print 2>/dev/null'
eval "$(fzf --zsh)"

# aliases
source $HOME/dotfiles/aliases.sh
zle -N search_command
bindkey '^]' search_command

# for AtCoder
alias actmp='cp ${HOME}/workspace/atcoder/template/template.py ./main.py; open ./main.py'
alias ojt='oj t -c "pypy3 ./main.py" -d tests'

# ls color setting
export LSCOLORS=hcfxcxdxbxegedabagacad

# history setting
# 履歴ファイルの保存先
export HISTFILE=${HOME}/.zsh_history
export HISTSIZE=1000
export SAVEHIST=100000
setopt hist_ignore_dups
setopt EXTENDED_HISTORY
setopt hist_no_store
setopt share_history

# completion
## AWS CLI
autoload bashcompinit && bashcompinit
autoload -Uz compinit && compinit
complete -C '/usr/local/bin/aws_completer' aws

## Git
zstyle ':completion:*:*:git:*' script /Library/Developer/CommandLineTools/usr/share/git-core/git-completion.bash
