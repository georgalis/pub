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

###### Major ./pub components
[root](https://github.com/georgalis/pub/)
* [./boot](./boot) Bootstrap scripts for various OS
* [./boot/nbsd/rc.sh](./boot/nbsd/rc.sh) invoke NetBSD bootstrap with CI/CD enhancements
* [./boot/nbsd/tai64n-inst.sh](./boot/nbsd/tai64n-inst.sh) tai64n and tai64nlocal installer
* [./know/music/5fb3-deja-muse.md](./know/music/5fb3-deja-muse.md) A 2020 Musical Playlist
* [./know/music/660e-requeues.tab](./know/music/660e-requeues.tab) WIP 2020 Musical Playlist
* [./know/Operations.pdf](know/Operations.pdf) Proceeding Operations brief graphical format
* [./know/ProOps](./know/ProOps/README.md) Proceeding Operations Framework detail
* [./mkinst/skel-inst.sh](./mkinst/skel-inst.sh) backup and install skel files
* [./skel](./skel) enhanced replacement default user env
* [./src/gpw](./src/gpw) pronounceable password generator
* [./sub/backlink.sh](./sub/backlink.sh) rsync hardlink snapshot backups
* [./sub/cc2netblock.sh](./sub/cc2netblock.sh) Country-Code to CIDR translator
* [./sub/fn.bash](./sub/fn.bash) functions to enhance user bash shell
* [./sub/prequeue](sub/prequeue) in transaction, smtp filter

###### Other repositories
* [../felidae](https://github.com/georgalis/felidae) Felidae AI/ML image classifier

## Public comments

* rmind/npf #113 [Solution](https://github.com/rmind/npf/issues/113#issuecomment-1157142538) Refer to range of IPs and use of wildcards

*  skafdasschaf/latex-pgfgantt #7 [Request/Alternative](https://github.com/skafdasschaf/latex-pgfgantt/issues/7#issuecomment-1149038354) High resolution time for gantt event analytics with pgfgantt

*  dylanaraps/pure-bash-bible #127 [Hint](https://github.com/dylanaraps/pure-bash-bible/pull/127#issuecomment-1081019748) exit behavior in functions

* Homebrew/brew #6637 [Solution](https://github.com/Homebrew/brew/issues/6637#issuecomment-545629991) 'keep' packages and 'orphaned' dependencies... 

* dylanaraps/pure-bash-bible #82 [Reference](https://github.com/dylanaraps/pure-bash-bible/issues/82#issuecomment-534194819) more rationale for not using #!/bin/bash? 

* pyenv/pyenv #1359 [Reference](https://github.com/pyenv/pyenv/pull/1359#issuecomment-504700287) Update shell configuration info in README 

* pyenv/pyenv #1347 [Reference](https://github.com/pyenv/pyenv/issues/1347#issuecomment-504034842) is putting "eval "$(pyenv init -)"" in ~/.bash_profile really a good suggestion? 

* usnistgov/OSCAL #349 [Alternative](https://github.com/usnistgov/OSCAL/issues/349#issuecomment-546127937) Consider using leading zeros in OSCAL Content Identifiers 

* [All Github Comments](https://github.com/search?q=commenter%3Ageorgalis)

