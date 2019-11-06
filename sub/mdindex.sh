#!/bin/bash

# discover all readme.md files, of git repos and
# parse "###### Summary" to create markdown links

# arg1 local home of repositories, default two directory above
[ "$1" ] && root="$1" || root="$(cd $(dirname "$0") && cd ../../ && pwd -P)"

# arg2, remote account, default author's github
[ "$2" ] && acct="$2" || acct="git@github.com:georgalis"

# generate url root prefix
name=${acct##*:}
urlbase="https://github.com/"

# discover all the repos in the root
find "$root" -regex '.*/\.git/config$' \
    -exec grep -q "url = ${acct}/" \{\} \; -print \
    | sed -e 's=\/\.git/config==' -e 's=//=/=' \
    | while IFS= read a ; do
        find "$a" -iname README.md # all the readme.md per repo
        done \
    | sort \
    | while IFS= read b; do
        # parse all the "###### Summary" lines per readme
        # generate full urls (deals with path /blob/master insertions)
        # then genetate markdown links
        c1="$(echo "${b%/*}" | sed "s,$root,..,")" # link display
        c2="$(echo "${b%/*}" | sed "s,$root,${urlbase}${name},")" # full url
        # output
        echo "* [${c1}](${c2}) $(sed -e '/^###### /!d' -e 's/^###### //' "$b")"
        done

# manually edit output into markdown...

