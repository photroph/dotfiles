export PATH

export TERM=xterm-256color
# prompt
PS1='%F{cyan}%~%F{green}
>%F{white}'

# aliases
alias ls='ls -FG'
alias ll='ls -lh'
alias rm='rm -i'

# for AtCoder
alias actmp='cp /Users/photroph/workspace/atcoder/template/template.py ./main.py; open ./main.py'
alias ojt='oj t -c "pypy3 ./main.py" -d tests'

# ls color setting
export LSCOLORS=hcfxcxdxbxegedabagacad
eval "$(starship init zsh)"
