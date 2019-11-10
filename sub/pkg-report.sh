#!/bin/sh

set -e 

devnul () { true ;} # non-verbose scheme
stderr () { echo "$*" 1>&2 ;} # return args to stderr
chkerr () { [ "$*" ] && { stderr ">>> $* <<<" ; return 1 ;} || true ;} #:> if args not null, err stderr args return 1
chkwrn () { [ "$*" ] && { stderr "^^ $* ^^" ; return 0 ;} || true ;} #:> if args not null, wrn stderr args return 0

env_qual () { # runtime qualification
    expr "$(uname)" : "NetBSD" >/dev/null || chkerr "Only tested on NetBSD : 5dc7129a" 
    } # env_qual
env_qual


#find /var/db/pkg.audit -mtime +1 -exec mv \{\} /var/db/pkg.audit.old \; || true

pkg_admin audit -e >/var/db/pkg.audit || true

printf '\n%s\n\n' "%%%% diff since review"

[ -e /var/db/pkg.audit.old ] \
  && diff /var/db/pkg.audit.old /var/db/pkg.audit \
  || true

#printf '\n%s\n\n' "%%%% newest"
#tail -n1 /var/db/pkg.audit

printf '\n%s\n\n' "%%%% package vulnerability count"

sed -e "
    s/^Package //
    s/ has a//
    s/ vulnerability, see http.*//
    " /var/db/pkg.audit | sort | uniq -c | awk '{print $2,$1,$3}'| column -t 

printf '\n%s\n\n' "%%%% package CVE(s)"

sed -e 's/^Package //' -e 's/ .*//' /var/db/pkg.audit \
    | sort -u | while read a ; do 
        printf "%s\n" "$a"
        { 
          sed -e "/$a/!d" -e 's=.*nvd.nist.gov/vuln/detail/==' \
                          -e 's,.*web.nvd.nist.gov/view/vuln/detail?vulnId=,,' \
              /var/db/pkg.audit \
            | tr '\n' ' ' | par 70 | column -t | sed -e 's/^/      /'  ;}
        echo
        done


[ -x /usr/local/sub/cve-tool.sh ] && \
    {
    printf '\n%s\n\n' "%%%% package CVE brief(s)"
    
    sed -e 's/^Package //' -e 's/ .*//' /var/db/pkg.audit \
        | sort -u | while read a ; do 
            printf "%s\n" "$a"
            /usr/local/sub/cve-tool.sh $( 
              sed -e "/$a/!d" -e 's=.*nvd.nist.gov/vuln/detail/==' \
                              -e 's,.*web.nvd.nist.gov/view/vuln/detail?vulnId=,,' \
                  /var/db/pkg.audit \
                | tr '\n' ' ' )
            echo
            done
    }

printf '\n\n%s\n\n' "%%%% full audit"

cat /var/db/pkg.audit

printf '\n%s\n\n' "%%%%"

