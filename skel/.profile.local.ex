# ~/.profile.local

path_prepend /opt/local/bin
path_prepend /opt/local/sbin
path_append $HOME/bin
path_append $HOME/sub

export EDITOR="vi"

alias gstat='git status'
alias gadd='git add'
alias gpush='git push'
alias gbranch='git branch'
alias gcom='git commit'
alias gdiff='git diff'
alias gco='git checkout'

#export MAILUSER="$(userinfo $USER | sed -ne '/login/s/login[^[:alnum:]]//p')"
#export MAILNAME="$(userinfo $USER | sed -ne '/gecos/s/gecos[^[:alnum:]]//p')"
#export MAILHOST="$(head -n1 /var/qmail/control/envnoathost)"
#export MAILBCC="$MAILUSER@$MAILHOST"

