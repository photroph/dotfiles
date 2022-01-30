export PATH

export TERM=xterm-256color
# prompt
PS1='%F{cyan}%~%F{green}
>%F{white}'

# aliases
alias la='ls -la'
alias ls='ls -FG'
alias ll='ls -lh'
alias rm='rm -i'

# for AtCoder
alias actmp='cp /Users/photroph/workspace/atcoder/template/template.py ./main.py; open ./main.py'
alias ojt='oj t -c "pypy3 ./main.py" -d tests'

# ls color setting
export LSCOLORS=hcfxcxdxbxegedabagacad
eval "$(starship init zsh)"

# history setting
# 履歴ファイルの保存先
export HISTFILE=${HOME}/.zsh_history
export HISTSIZE=1000
export SAVEHIST=100000
setopt hist_ignore_dups
setopt EXTENDED_HISTORY
setopt hist_no_store

