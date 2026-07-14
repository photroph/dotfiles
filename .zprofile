#!/bin/zsh
# test -r ~/.bashrc && . ~/.bashrc
export PATH=/usr/local/bin:/bin:/sbin:/usr/bin:/usr/sbin:~/bin:/opt/homebrew/bin:$HOME/Library/Android/sdk/platform-tools/

# pyenv settings
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# poetry
export PATH="$HOME/.local/bin:$PATH"

# volta settings
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

export ANDROID_HOME="$HOME/Library/Android/sdk/"
export JAVA_HOME="/Library/Java/JavaVirtualMachines/jdk-19.jdk/Contents/Home/"

# use Homebrew
export PATH="/opt/homebrew/bin:$PATH"

# 対話シェルでのみ、dotfiles のシンボリックリンクを張る
if [[ -o interactive ]]; then
  bash "$HOME/dotfiles/scripts/setup_symlinks.sh"

  # Auto-start tmux when attached to a terminal
  if [[ -z "$TMUX" && -t 0 && -t 1 ]]; then
    echo -n "tmux session name: "
    read session_name
    tmux new-session -A -s "$session_name"
  fi
fi
