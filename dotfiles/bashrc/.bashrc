#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
export JAVA_HOME='/usr/lib/jvm/default'
export ANDROID_SDK_ROOT='/opt/android-sdk'
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools/
export PATH=$PATH:$ANDROID_HOME/tools/bin/
export PATH=$PATH:$ANDROID_HOME/tools/
export CHROME_EXECUTABLE=/usr/bin/vivaldi-stable
PATH=$ANDROID_HOME/emulator:$PATH
PS1='[\u@\h \W]\$ '
complete -cf sudo
fish
