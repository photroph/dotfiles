PATH=/bin:/usr/bin:/usr/local/bin:${PATH}
export PATH
PS1='\n\[\e[36m\]\W \[\e[00m\]\$ '

alias ls='ls -FG'
alias ll='ls -lh'
export TERM=xterm-256color

# ls color setting
export LSCOLORS=hcfxcxdxbxegedabagacad
eval "$(starship init zsh)"
