# ~/.zlogout

## TRAPEXIT () set in ~/.zshrc for same functionality.
# 
# [ -n "$SSH_AGENT_ENV" ] && set $SSH_AGENT_ENV && [ "$$" = "$4" ] \
# 	&& { printf "Logout: " && kill $2 && echo $(hostname) $0 [$4] killed ssh-agent $2 \
# 		|| { echo $(hostname) ssh-agent already died? 2>/dev/stderr ; exit 1 ;} ;}

