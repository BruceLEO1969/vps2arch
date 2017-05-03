#!/bin/bash

set -o errexit
set -o nounset
set -o errtrace
set -o pipefail

# privilege check
privilege_check(){
  if [[ $EUID -eq 0 ]]
  then
    echo "We are sorry, but you should only run this script on a non-root user."
    exit 0
  fi
}

# zsh config
zsh_config(){
  cd ~
  mkdir -p .antigen
  echo "Setting up antigen, just be patients."
  curl -L git.io/antigen > .antigen/antigen.zsh &>/dev/null
  echo "Update .zshrc file."
  curl -LO https://raw.githubusercontent.com/BruceLEO1969/vps2arch/master/.zshrc &>/dev/null
  echo "zsh_config finished."
}

# tmux_config
tmux_config(){
  rm -rf .tmux
  git clone https://github.com/BruceLEO1969/.tmux.git &>/dev/null
  ln -s -f .tmux/.tmux.conf
  cp .tmux/.tmux.conf.local .
  echo "tmux setup finished."
}

# main function
main(){
  privilege_check
  zsh_config
  tmux_config
}

main
