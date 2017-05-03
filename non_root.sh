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
  mkdir -p .antigen
  echo "Setting up antigen, just be patients."
  curl -L git.io/antigen > .antigen/antigen.zsh &>/dev/null
  echo "Update .zshrc file."
  curl -LO 
}
# main function
main(){
  privilege_check
}

main
