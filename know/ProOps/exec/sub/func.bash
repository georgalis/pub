#/usr/bin/env bash

# Sundry functions
# Unlimited use with this notice. (C) 2004-2020 George Georgalis

chkerr () { [ "$*" ] && { stderr ">>> $* <<<" ; return 1 ;} || true ;} #:> if args not null, err stderr args return 1
chkwrn () { [ "$*" ] && { stderr "^^ $* ^^" ; return 0 ;} || true ;} #:> if args not null, wrn stderr args return 0
catwrn () { local LINE ; while IFS= read LINE ; do chkwrn "$LINE" ; done ;} # decorate stdin to stderr return 0
stderr () { echo "$*" 1>&2 ;} # return args to stderr
devnul () { true ;} # expect nothing in return

grep -q "^CentOS Linux release 7" /etc/centos-release || { 
    chkwrn "Probably works on Ubuntu, untested"
    chkwrn "Probably works on NetBSD, untested"
    chkwrn "Probably works on CentOS, non 7 release, untested"
    chkerr "$(uname) : running on untested OS" ; return 1 ;}

# more test
# echo "$SHELL"
# echo "$BASH_VERSINFO"      "${BASH_VERSINFO[0]}" "${BASH_VERSINFO[1]}" "${BASH_VERSINFO[2]}"
# echo "${BASH_VERSINFO[3]}" "${BASH_VERSINFO[4]}" "${BASH_VERSINFO[5]}" x "${BASH_VERSINFO[6]}"

addusers () {
local prefix="$1"
[ -n "$prefix" ] || { cat 1>&2 <<EOF
# $FUNCNAME
# minimal etc and home manipulation for ssh shell accounts
# maintains a subset of passwd and group lines, with duplication checks,
# arg1 should be the prefix where user.tbl and group.tbl files are located
# for ssh key only access and sshd_conf for /etc/ssh/auth/user.pub
#
# generally this function is copied with data, then remotely invoked.
# exactly one login, uid, group, gid, per passwd, shadow, user.tbl, group.tbl
# create mode 700 home if nonexistent, from skel, install pub keys.
# ignore: subgid and subuid (per user docker ranges), easy add.
#
# formats:
# group   GROUP:x:GID:
# gshadow GROUP:!:
# passwd  LOGIN:x:UID:GID:GECOS:DIR:SH
# shadow  LOGIN:!:
#
EOF
return 1 ;} # usage
    # many error checks because big problems on fail
    local prefix="$1" LINE LOGIN GROUP DIR q
    [ -d "$prefix" ] || { chkerr "$FUNCNAME : source data prefix not a directory" ; return 1 ;}
    cd "$prefix"     || { chkerr "$FUNCNAME : cannot cd prefix"                   ; return 1 ;}
    local USERS="$PWD/user.tbl" GRPS="$PWD/group.tbl"
    cd "$OLDPWD"
    [ -f "$USERS" ] || { chkerr "$FUNCNAME : no $USERS file" ; return 1 ;}
    [ -f "$GRPS"  ] || { chkerr "$FUNCNAME : no $GRPS file"  ; return 1 ;}
    local out=/etc
    [ -f "$out/passwd" ] || { chkerr "$FUNCNAME : no existing $out/passwd file" ; return 1 ;}
    [ -f "$out/group"  ] || { chkerr "$FUNCNAME : no existing $out/group file" ;  return 1 ;}
    clean_addusers () { rm -f "$out/group-$$" "$out/group-$$~" "$out/gshadow-$$" "$out/passwd-$$" "$out/passwd-$$~" "$out/shadow-$$" ;}
    touch                     "$out/group-$$" "$out/group-$$~" "$out/gshadow-$$" "$out/passwd-$$" "$out/passwd-$$~" "$out/shadow-$$" \
                              "$out/group"                     "$out/gshadow"    "$out/passwd"                      "$out/shadow" \
      || { chkerr "$FUNCNAME : output privilege" ; return 1 ;}
    # create group data
    rm -f "$out/shadow-$$"
    sed -e '/^#/d' -e 's/#.*//' -e 's/[ ]*$//' "$GRPS" \
      | while IFS= read LINE; do
        GROUP="${LINE%%:*}"
        sed "/^${GROUP}:/d" "$out/group" >>"$out/group-$$" || { chkerr "$FUNCNAME : cannot write group tmp file" ; clean_addusers ; return 1 ;}
        echo "$LINE"                     >>"$out/group-$$"
        done # LINE
    # remove collation artifacts (line duplication)
    sort -k3 -t: -n "$out/group-$$" >"$out/group-$$~" && mv "$out/group-$$~" "$out/group-$$" || { chkerr "$FUNCNAME : sort group error" ; clean_addusers ; return 1 ;}
    uniq            "$out/group-$$" >"$out/group-$$~" && mv "$out/group-$$~" "$out/group-$$" || { chkerr "$FUNCNAME : uniq group error" ; clean_addusers ; return 1 ;}
    # break on duplicate group or GID...
    q="$(cut -d: -f 3 "$out/group-$$" | uniq -d | tr '\n' ' ')"
    [ ! "$q" ] || { chkerr "$FUNCNAME : duplicate gid $q : $GRPS $out/group" ; clean_addusers ; return 1 ;}
    q="$(cut -d: -f 1 "$out/group-$$" | sort | uniq -d | tr '\n' ' ')"
    [ ! "$q" ] || { chkerr "$FUNCNAME : duplicate group $q : $GRPS $out/group" ; clean_addusers ; return 1 ;}
    sed -e "s/:.*/:!::/" "$out/group-$$" >"$out/gshadow-$$"
    # create user data
    rm -f "$out/shadow-$$" "$out/passwd-$$"
    sed -e '/^#/d' -e 's/#.*//' -e 's/[ ]*$//' "$USERS" \
      | while IFS= read LINE; do
        LOGIN="${LINE%%:*}"
        sed "/^${LOGIN}:/d" "$out/passwd" >>"$out/passwd-$$" || { chkerr "$FUNCNAME : cannot write passwd tmp file" ; clean_addusers ; return 1 ;}
        echo "$LINE"                      >>"$out/passwd-$$"
        done # LINE
    # remove collation artifacts (line duplication)
    sort -k3 -t: -n "$out/passwd-$$" >"$out/passwd-$$~" && mv "$out/passwd-$$~" "$out/passwd-$$" || { chkerr "$FUNCNAME : sort passwd error" ; clean_addusers ; return 1 ;}
    uniq            "$out/passwd-$$" >"$out/passwd-$$~" && mv "$out/passwd-$$~" "$out/passwd-$$" || { chkerr "$FUNCNAME : uniq passwd error" ; clean_addusers ; return 1 ;}
    # break on duplicate LOGIN or UID...
    q="$(cut -d: -f 3 "$out/passwd-$$" | uniq -d | tr '\n' ' ')"
    [ ! "$q" ] || { chkerr "$FUNCNAME : duplicate uid $q : $USERS $out/passwd"   ; clean_addusers ; return 1 ;}
    q="$(cut -d: -f 1 "$out/passwd-$$" | sort | uniq -d | tr '\n' ' ')"
    [ ! "$q" ] || { chkerr "$FUNCNAME : duplicate login $q : $USERS $out/passwd" ; clean_addusers ; return 1 ;}
    # create shadow
    sed -e "s/:.*/:!!:::::::/" "$out/passwd-$$" >"$out/shadow-$$"
    # backup and install files
    cp -fp "$out/gshadow"    "$out/gshadow-" || { chkerr "$FUNCNAME : cannot create gshadow-" ; clean_addusers ; return 1 ;}
    mv -f  "$out/gshadow-$$" "$out/gshadow"  || { chkerr "$FUNCNAME : cannot create gshadow"  ; clean_addusers ; return 1 ;}
    cp -fp "$out/group"      "$out/group-"   || { chkerr "$FUNCNAME : cannot create group-"   ; clean_addusers ; return 1 ;}
    mv -f  "$out/group-$$"   "$out/group"    || { chkerr "$FUNCNAME : cannot create group"    ; clean_addusers ; return 1 ;}
    cp -fp "$out/shadow"     "$out/shadow-"  || { chkerr "$FUNCNAME : cannot create shadow-"  ; clean_addusers ; return 1 ;}
    mv -f  "$out/shadow-$$"  "$out/shadow"   || { chkerr "$FUNCNAME : cannot create shadow"   ; clean_addusers ; return 1 ;}
    cp -fp "$out/passwd"     "$out/passwd-"  || { chkerr "$FUNCNAME : cannot create passwd-"  ; clean_addusers ; return 1 ;}
    mv -f  "$out/passwd-$$"  "$out/passwd"   || { chkerr "$FUNCNAME : cannot create passwd"   ; clean_addusers ; return 1 ;}
    # home and keys
    mkdir -p "$out/ssh/auth" || { chkerr "$FUNCNAME : cannot create $out/ssh/auth" ; return 1 ;}
    sed -e '/^#/d' -e 's/#.*//' -e 's/[ ]*$//' "$USERS" \
      | while IFS= read LINE; do
        LOGIN="${LINE%%:*}" # just the first field
          DIR="${LINE%:*}"  # cut off the last field
          DIR="${DIR##*:}"  # just the last field
        # create user home if needed
        [ -d "$DIR" ] || install -d -m 700 -o "$LOGIN" -g "$LOGIN" /etc/skel "$DIR" || { chkerr "$FUNCNAME : cannot create $DIR" ; clean_addusers ; return 1 ;}
        # append .forward with GECOS <email@domain> if needed, XXX not working
        #e=$(echo "$LINE" | cut -d: -f5 | sed -e 's/.*<//' -e 's/>.*//')
        #expr "$e" : '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$' >/dev/null && echo y || echo n
        #grep -q "^${e}$" $DIR/.forward || echo "$e" >>$DIR/.forward
        #chown $LOGIN:$LOGIN $DIR/.forward
        # install ssh pub keys
        [ -e "$prefix/ssh/auth/${LOGIN}.pub" ] && cp "$prefix/ssh/auth/${LOGIN}.pub" "$out/ssh/auth" \
            || { rm -f "$out/ssh/auth/${LOGIN}.pub" ; chkwrn "No pub key for ${LOGIN}.pub" ;}
        done
    } # addusers

