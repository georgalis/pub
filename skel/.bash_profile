# ~/.bash_profile

# (c) 2006-2022 George Georgalis <george@galis.org> unlimited use with this notice 

# source any legacy rc
test -e ~/.bashrc && . ~/.bashrc || true

# source root env
test -e ~/.profile  && . ~/.profile

# no further env setup here.
