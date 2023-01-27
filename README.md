# georgalis @ Github 

_The way I roll..._
```
git archive --prefix ./pub/ main | gzip -c | ssh remote "tar xzf -"
```
or
```
h=srv r="$HOME/vcs/pub" t=$(cd /tmp && mktemp -d ./gitarch-XXXX)
cd "${r}" && git archive --prefix ${PWD##*/}/ HEAD | tar -C "/tmp/${t}" -xzf - \
 && rsync -vrtcpz --chmod=Fa-w "/tmp/${t}/${PWD##*/}/" root@${h}:/usr/local/${PWD##*/}/ \
 && rm -rf "/tmp/${t}/"
```

###### Shortcuts to major ./pub components

[root](https://github.com/georgalis/pub/)
* [./know/](./know/README.md#edification) corporeal resources
* [./know/music/](.//know/music/README.md#music-curation) Musical Playlists
* [./know/music/5fb3-deja-muse.md](./know/music/5fb3-deja-muse.md#5fb3-deja-muse) A 2020 Musical Playlist
* [./know/Nevermind.pdf](./know/Nevermind.pdf) life management
* [./know/Operations.pdf](./know/Operations.pdf) Proceeding Operations, brief graphical format
* [./know/ProOps](./know/ProOps/README.md) Proceeding Operations Framework, text detail
* [./boot](./boot) bootstrap scripts for various OS
* [./boot/nbsd/rc.sh](./boot/nbsd/rc.sh) invoke NetBSD bootstrap with CI/CD enhancements
* [./boot/nbsd/tai64n-inst.sh](./boot/nbsd/tai64n-inst.sh) tai64n and tai64nlocal installer
* [./mkinst/skel-inst.sh](./mkinst/skel-inst.sh) backup and install skel files
* [./skel](./skel) default user env (enhanced replacement)
* [./src/gpw](./src/gpw) pronounceable password generator
* [./src/multitee/multitee-3.0a/](./src/multitee/multitee-3.0a/) build multitee-3.0 with modern compilers
* [./sub/backlink.sh](./sub/backlink.sh) rsync hardlink snapshot backups
* [./sub/cc2netblock.sh](./sub/cc2netblock.sh) Country-Code to CIDR translator
* [./sub/fn.bash](./sub/fn.bash) functions to enhance bash shell
* [./sub/prequeue](./sub/prequeue) in transaction, smtp filter

###### Other repositories
* [../felidae](https://github.com/georgalis/felidae) Felidae AI/ML image classifier
* [rust translation](https://github.com/georgalis/colab-61cc/pull/1) PR for [nm2rgb.py](https://github.com/georgalis/colab-61cc/tree/tint/tint)

### Public comments

* OSX Ventura rsync to msdos/usb fail --- [apple discussion 254383328](https://discussions.apple.com/thread/254383328), breaks rsync maintenance of IoT micro sd flash memory, [github rsync issue](https://github.com/WayneD/rsync/issues/412)

* [\_mbsetupuser uses /bin/bash](https://discussions.apple.com/thread/254233125) --- Macs ship with a 2007 version of bash, supported or not?

* Github Copilot docs update? Not today... [Issue #19579](https://github.com/community/community/discussions/19579) [PR #18833](https://github.com/github/docs/pull/18833)

* [https://github.com/tmux/tmux/issues/3220](tmux/tmux #3220) Add a comand line option to disable acl checking... nope!

* rmind/npf #113 [Solution](https://github.com/rmind/npf/issues/113#issuecomment-1157142538) Refer to range of IPs and use of wildcards

*  skafdasschaf/latex-pgfgantt #7 [Request/Alternative](https://github.com/skafdasschaf/latex-pgfgantt/issues/7#issuecomment-1149038354) High resolution time for gantt event analytics with pgfgantt

*  dylanaraps/pure-bash-bible #127 [Hint](https://github.com/dylanaraps/pure-bash-bible/pull/127#issuecomment-1081019748) exit behavior in functions

* Homebrew/brew #6637 [Solution](https://github.com/Homebrew/brew/issues/6637#issuecomment-545629991) 'keep' packages and 'orphaned' dependencies... 

* dylanaraps/pure-bash-bible #82 [Reference](https://github.com/dylanaraps/pure-bash-bible/issues/82#issuecomment-534194819) more rationale for not using #!/bin/bash? 

* pyenv/pyenv #1359 [Reference](https://github.com/pyenv/pyenv/pull/1359#issuecomment-504700287) Update shell configuration info in README 

* pyenv/pyenv #1347 [Reference](https://github.com/pyenv/pyenv/issues/1347#issuecomment-504034842) is putting `eval "$(pyenv init -)"` in `~/.bash_profile` really a good suggestion? 

* usnistgov/OSCAL #349 [Alternative](https://github.com/usnistgov/OSCAL/issues/349#issuecomment-546127937) Consider using leading zeros in OSCAL Content Identifiers 

* [All Github Comments](https://github.com/search?q=commenter%3Ageorgalis)

