export PATH
autoload -U colors && colors
export TERM="xterm-256color"

# prompt
# PS1='%F{cyan}%~%F{green}
# >%F{white}'
eval "$(starship init zsh)"
# Set up fzf key bindings and fuzzy completion
eval "$(fzf --zsh)"

# aliases
source $HOME/dotfiles/aliases.sh

# for AtCoder
alias actmp='cp /Users/photroph/workspace/atcoder/template/template.py ./main.py; open ./main.py'
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

# completion
## AWS CLI
autoload bashcompinit && bashcompinit
autoload -Uz compinit && compinit
complete -C '/usr/local/bin/aws_completer' aws

## Git
zstyle ':completion:*:*:git:*' script /Library/Developer/CommandLineTools/usr/share/git-core/git-completion.bash
