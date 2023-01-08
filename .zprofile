#!/bin/zsh
# test -r ~/.bashrc && . ~/.bashrc
# export PATH=$PATH:~/.composer/vendor/bin/
# export PATH="/usr/local/opt/php@7.3/bin:$PATH"
# export PATH="/usr/local/opt/php@7.3/sbin:$PATH"
export PATH=/usr/local/bin:/bin:/sbin:/usr/bin:/usr/sbin:~/bin:/opt/homebrew/bin:$HOME/Library/Android/sdk/platform-tools/
# Add Visual Studio Code (code)
# export PATH="\$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

# pyenv settings
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# volta settings
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

export ANDROID_HOME="$HOME/Library/Android/sdk/"
export JAVA_HOME="/Library/Java/JavaVirtualMachines/jdk-19.jdk/Contents/Home/"
