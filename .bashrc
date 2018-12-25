# .bashrc

# User specific aliases and functions

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Source global definitions
if [ -f /etc/bashrc  ]; then
	. /etc/bashrc
fi

export PATH=$PATH:/usr/local/bin:$HOME/bin
export EDITOR=vim

cd /data/Server
. ./build_env.sh

alias n='/etc/motd.sh'
