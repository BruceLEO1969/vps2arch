source ~/.antigen/antigen.zsh

# Load the oh-my-zsh's library.
antigen use oh-my-zsh

# # Bundles from the default repo (robbyrussell's oh-my-zsh).
antigen bundle z
antigen bundle git
antigen bundle heroku
antigen bundle pip
antigen bundle command-not-found
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-completions

# # Load the theme.
antigen theme agnoster

# # Tell antigen that you're done.
antigen apply

DEFAULT_USER=$USER
prompt_context(){}

#http proxy
function proxy(){
  no_proxy="127.0.0.1, localhost"
  export http_proxy="http://127.0.0.1:1087"
  export https_proxy=$http_proxy
}

function noproxy(){
  unset http_proxy
  unset https_proxy
}

#alias
alias tm='tmux att -t Tmux || tmux new -s Tmux'
alias cat=ccat
alias ndig='dig +noall +answer'

#vi mode
bindkey -v

bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char
bindkey '^w' backward-kill-word
bindkey '^r' history-incremental-search-backward

precmd() { RPROMPT=""  }
function zle-line-init zle-keymap-select {
  VIM_PROMPT="%{$fg_bold[red]%} % 🐔 %{$reset_color%}"
  RPS1="${${KEYMAP/vicmd/$VIM_PROMPT}/(main|viins)/} $EPS1"
  zle reset-prompt
}

zle -N zle-line-init
zle -N zle-keymap-select

export KEYTIMEOUT=1

mobi(){
  antigen theme robbyrussell
}