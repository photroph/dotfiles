export PATH
autoload -U colors && colors
export TERM="xterm-256color"

# prompt
# PS1='%F{cyan}%~%F{green}
# >%F{white}'
eval "$(starship init zsh)"

# aliases
alias exa='exa --icons'
alias el='exa -lh'
alias ela='el -a'
alias gd='git diff --unified=1'
alias gs='git status'
alias la='ls -la'
alias ls='ls -FG'
alias ll='ls -lh'
alias nv='nvim'
alias rm='rm -i'

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

