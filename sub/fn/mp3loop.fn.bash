mp3loop () ( # play a directory of mp3 files as a continuous loop, with remote control
# revisions
#   6acd6600-20261012_155808 normalize to standard function style; integrate
#     playffr; state schema ~/0/v/mp3loop_*; remote control (-e -r, USR1/TERM);
#     -s stop time (hex or +N[smhdw]); -n signed skip relative to the current
#     track, last setting wins; -p preview; -m memory only (no writes, survives
#     hangup, remote by signal and ps); name safety classes, warn and error
#     log; directory change by mtime; hms2sec via awk; -h usage, --help manual
#   6542c3b7-20231101_143125 playffr: play files (args or stdin) with ffplay,
#     no display; volume read per track from playff_vol (0 stops); "file PWD"
#     recorded in playff before each track
#   64e3caf9-20230821_133703 mp3loop: rotate a directory list at a lexicographic
#     mark, store it, pipe it to playffr; -v volume 1-100 (invalid: 88); skip
#     0* and y* names
#
# purpose
#   Loop the mp3 files of one directory in sequence order from a start point,
#   wrapping after the last track, until a stop condition. Invoked while a loop
#   plays, act as a remote: reprogram the loop's state, signal it, print the
#   resulting plan. Drives a local workstation, or a headless network attached
#   player (storage, amplifier, speakers) commanded over ssh from a workstation.
#
# requirements
#   -m         memory only: no state or log reads or writes, TARGET required,
#              hangup and broken pipe ignored, messages to the terminal or,
#              once it is gone, /dev/null; remote limited to -e (TERM, stop)
#              and -n -e (USR1, next), found through a ps beacon
#   -v VOL     1-100; 0 stops at the next track boundary
#   -s WHEN    latest track start: hex unix seconds right padded to 8 digits
#              (6ace = 6ace0000), or +N[smhdw] (m default); 0 clears; past is
#              an error; a stop resets the stored value to 0
#   -n [N]     signed, default 1; deferred: skip N after the current track
#              (0 continues normally, -1 replays it); with -e: skip from the
#              current track (1 next, 0 restart, -1 previous); with TARGET:
#              TARGET plus N; each remote -n replaces the last, no accumulation
#   -p [N]     preview N tracks before each play (default 10); remote: also
#              print the queue and directory in the remote terminal
#   -e         apply now; alone, stop the loop
#   -r         apply after the current track; implied for a remote call; with
#              no player, record state for the next start without playing
#   values attach or follow (-v55, -v 55); a following integer after -n
#   (signed) or -p is taken as its value; -- ends options
#   TARGET     DIR | FILE | PATH/FRAG | FRAG (last played directory); an
#              existing file wins over a FRAG of the same name
#   order      C locale; sequence id is the alnum prefix ending at the first
#              comma (any base); equal ids play in name order; no id: warn
#   names      safe set [A-Za-z0-9._,+^-]; 0* and y* are not played; warn
#              class plays and is logged;
#              error class (incl. non-printable) is skipped and logged; log
#              names carry X for error chars and _ for spaces
#   precedence option, then state file (hint), then default; a stored
#              volume 0 refuses a start until -v is given
#   a pending request survives a stop and becomes the next start point
#
# constraints
#   bash 4.2+ (printf %()T, BASHPID, mapfile, =~). The body is a subshell:
#   helpers, traps, LC_ALL and shopt never reach the caller, and the helper
#   names (chkwrn, chktrue, hms2sec, ...) may shadow the environment's freely.
#   DIR is only read (atime is touched). State lives in ~/0/v/mp3loop_*, made
#   only on first write; the schema is owned here. ffplay and ffprobe resolve
#   through PATH at run time; an alias such as ffplay8 applies only when
#   defined before this function is sourced, and never in a non-interactive
#   ssh call (aliases are expanded when a function is defined, and are off in
#   non-interactive shells), so a headless player should use a PATH entry or
#   a symlink named ffplay. stat is probed once for GNU (-c %Y) or BSD (-f %m).
#
# state protocol
#   The player reads all state at each track boundary, so a remote write or a
#   hand edit applies when the current track ends; USR1 moves the boundary to
#   now, TERM stops now. mp3loop_pos is both record and request: the player
#   writes the current track there as one line; a remote writes the path plus
#   a second line, request. At the boundary, a second line or a path other
#   than the current track is a request to play from that path (exact name,
#   FRAG, or DIR/ for the first track), so a request to replay the current
#   track is seen, and a hand edit of the path is one. (An inode test was
#   tried and dropped: inode numbers are reused.) mp3loop_pid carries the
#   player pid, its start time (guards against a reused pid) and the current
#   track, for remote display. The list lives in memory with the directory
#   mtime; the list file is rewritten only when the mtime changes. With -m no
#   file is read or written: a renamed sleep (argv0 mp3loop_memory) child of
#   the player is its ps beacon, and ffplay's arguments give track and volume.
#
# known limits, future
#   no lock against two simultaneous starts; a directory change within the
#   second of a scan may be missed (a vanished track forces a rescan); a
#   memory only remote cannot program volume, stop, preview or position;
#   amplifier relay control

    export LC_ALL=C ; shopt -s nullglob

    # --- state schema: one prefix in ~/0/v, no dedicated directory
    v="$HOME/0/v/mp3loop"
    pos_f="${v}_pos" vol_f="${v}_vol" stop_f="${v}_stop" stopped_f="${v}_stopped"
    prev_f="${v}_preview" list_f="${v}_list" pid_f="${v}_pid" err_f="${v}_err"

    # --- name classes: error = shell or glob active, control, non-ascii
    err_re=$'[^[:print:]]|[][\'"`(){};#$@!%*?&|<>\\]'   # regex test
    err_glob=$'[][\'"`(){};#$@!%*?&|<>\\\\]'            # same set, for ${x//}
    wrn_re='[^A-Za-z0-9._,+^/-]'                        # outside the safe set (^ splits id from data)

    # --- helpers (subshell scoped)
    stderr () { [ "$*" ] && echo "$*" 1>&2 || : ;}
    chkwrn () { [ "$*" ] && { stderr "^^^ $*" ; return $? ;} || : ;}
    chkerr () { [ "$*" ] && { stderr ">>> $*" ; return 1 ;} || : ;}
    chktrue () { [ "$*" ] && { stderr "><> $*" ; : ;} || return 2 ;}
    hms2sec () { # passthrough seconds or convert hh:mm:ss to seconds
        # must provide ss which may be ss.nn, hh: and hh:mm: are optional
        # a number must proceed every colon; awk replaces dc, same interface
        # (up to 6 decimals), and the error now returns 1 outside the pipeline
      [[ $1 == *:*:*:* ]] && { chkerr "too many ':' in '$1' (6542c9ba)" ; return 1 ;}
      { [[ $1 == *:* ]] \
          && echo $1 | awk -F: '{ s = 0 ; for (i = 1 ; i <= NF ; i++) s = s * 60 + $i ; printf "%.6f\n", s }' \
          || echo $1
      } | sed -e '/\./s/[0]*$//' -e 's/\.$//' ;} # hms2sec
    usage_err () { chkerr "mp3loop : $1 (6acd4f02)" ; stderr "try: mp3loop -h" ; exit 2 ;}
    now () { printf -v now '%(%s)T' -1 ;}
    stamp () { now ; printf -v stamp '%x-%(%Y%m%d_%H%M%S)T' "$now" "$now" ;}
    isnum () { [[ $1 =~ ^[0-9]+$ ]] ;}
    isint () { [[ $1 =~ ^-?[0-9]+$ ]] ;}
    isvol () { isnum "$1" && (( 10#$1 <= 100 )) ;}
    get () { val='' ; [ -f "$1" ] && { read -r val <"$1" || : ;} || : ;}
    getpos () { val='' val2='' ; [ -f "$pos_f" ] && { { read -r val ; read -r val2 ;} <"$pos_f" || : ;} || : ;}
    put () { # atomic state write: tmp then mv, never a partial read; none with -m
        [ "$mem" ] && return 0
        [ -d "$1" ] && { chkerr "mp3loop : state path '$1' is a directory (6acd4f03)" ; return 1 ;}
        [ -d "${1%/*}" ] || mkdir -p "${1%/*}" || return 1
        printf '%s\n' "$2" >"${1}.tmp.$BASHPID" && mv -f "${1}.tmp.$BASHPID" "$1" ;}
    xname () { x="${1//[![:print:]]/X}" ; x="${x//$err_glob/X}" ; x="${x// /_}" ;}
    logname () { # $1 class (warn, error), $2 path; none with -m
        [ "$mem" ] && return 0
        [ -d "${err_f%/*}" ] || mkdir -p "${err_f%/*}" || return 1
        xname "$2" ; stamp ; printf '%s %s %s\n' "$stamp" "$1" "$x" >>"$err_f" ;}
    mtime () { # directory mtime in m; stat flavor probed once
        [ ${#st[@]} -gt 0 ] || { stat -c %Y / >/dev/null 2>&1 && st=(-c %Y) || st=(-f %m) ;}
        read -r m < <(stat "${st[@]}" "$1" 2>/dev/null) || m='' ;}
    dirok () { # realpath of $1 into rdir; error class directory is logged, refused
        read -r rdir < <(cd -P -- "$1" 2>/dev/null && pwd -P) \
          || { chkerr "mp3loop : no directory '$1' (6acd4f04)" ; return 1 ;}
        [[ $rdir =~ $err_re ]] && { logname error "$rdir" ; xname "$rdir"
            chkerr "mp3loop : unsafe directory '$x' (6acd4f05)" ; return 1 ;} ; return 0 ;}
    stopdesc () { # stored stop hex to "hex (date)" or none
        get "$stop_f"
        [[ $val =~ ^[0-9a-f]{8}$ ]] && (( 16#$val )) \
          && printf '%s (%(%a %d %b %H:%M)T)' "$val" $(( 16#$val )) || printf 'none' ;}

    stopparse () { # WHEN to 8 hex digits in stop_x; 0 clears
        local w="$1" e=0
        now
        [[ $w =~ ^\+([0-9]{1,9})([smhdw]?)$ ]] && {
            case "${BASH_REMATCH[2]:-m}" in
            s) e=1 ;; m) e=60 ;; h) e=3600 ;; d) e=86400 ;; w) e=604800 ;;
            esac
            e=$(( now + 10#${BASH_REMATCH[1]} * e )) ;} \
          || { [[ $w =~ ^[0-9a-fA-F]{1,8}$ ]] || { chkerr "mp3loop : bad stop time '$1' (6acd4f06)" ; return 1 ;}
            printf -v w '%-8s' "$w" ; w="${w// /0}" ; e=$(( 16#$w )) ;}
        (( e == 0 )) && { stop_x=0 ; return 0 ;}
        (( e > now )) || { chkerr "mp3loop : stop time '$1' is past (6acd4f07)" ; return 1 ;}
        (( e <= 0xffffffff )) || { chkerr "mp3loop : stop time '$1' beyond 8 hex digits (6acd4f08)" ; return 1 ;}
        printf -v stop_x '%08x' "$e" ;}

    scan () { # list dir into L (n entries), warnings W, mtime dmt; $1 = w: player, write list, log names
        local f b ; L=() W=()
        mtime "$dir" ; dmt="$m" # taken before the glob, so a later change is seen
        [[ $dir =~ $wrn_re ]] && { W+=("unsafe characters in directory: $dir") ; [ "${1-}" ] && logname warn "$dir" ;}
        for f in "$dir"/*.mp3 ; do b="${f##*/}"
            [ -f "$f" ] && [[ $b != [0y]* ]] || continue
            [[ $b =~ $err_re ]] && { [ "${1-}" ] && logname error "$f" ; xname "$b"
                W+=("skipped, unsafe name: $x") ; continue ;}
            [[ $b =~ $wrn_re ]] && { W+=("unsafe characters: $b") ; [ "${1-}" ] && logname warn "$f" ;}
            [[ $b =~ ^[0-9A-Za-z]+, ]] || W+=("no sequence id: $b")
            L+=("$b")
          done
        n=${#L[@]}
        [ "${1-}" ] && { printf -v b '%s\n' "${L[@]/#/$dir/}" ; put "$list_f" "${b%$'\n'}" ;} ; return 0 ;}
    locate () { # index of the first entry sorting at or after $1 (empty: first); exact=1 on match
        local i ; idx=0 exact=0
        [ "$1" ] || return 0
        for (( i = 0 ; i < n ; i++ )) ; do [[ ${L[i]} < $1 ]] && continue
            idx=$i ; [ "${L[i]}" = "$1" ] && exact=1 ; return 0
          done ; return 0 ;} # past the last entry: wrap to the first
    wrap () { idx=$(( (($1) % n + n) % n )) ;} # signed index into 0..n-1
    preview () { # print $1 entries from index $2, far to near
        local k ; for (( k = $1 - 1 ; k >= 0 ; k-- )) ; do echo "${L[($2 + k) % n]}" ; done ;}
    plan () { # one line: $1 label; vol, next track, stop as stored
        get "$vol_f" ; printf '%s: vol %s; next %s; stop %s\n' "$1" "${val:-none}" "${next:-none}" "$(stopdesc)" ;}

    usage () { cat ;} <<'eof'
mp3loop --- play a directory of mp3 files as a continuous loop
usage: mp3loop [-m] [-v VOL] [-s WHEN] [-n [N]] [-p [N]] [-e|-r] [TARGET]
  -m          memory only: no state or log files, survives hangup
  -v VOL      volume 1-100; 0 stops at the end of the current track
  -s WHEN     no track starts after WHEN: hex unix seconds
              (6ace = 6ace0000), or +N[smhdw] from now (m default);
              0 clears
  -n [N]      skip N tracks after the current one (default 1);
              with -e, from the current one; N may be negative
  -p [N]      preview the next N tracks before each play (default 10)
  -e          remote: apply now; alone, stop the current play
  -r          remote: apply after the current track (default)
  -h, --help  this summary, or the full manual
TARGET  DIR | FILE | PATH/FRAG | FRAG (in the last played directory)
A call made while a loop is playing is a remote: it reprograms
the playing loop, prints the resulting plan, and returns.
eof
    manual () { cat ;} <<'eof'
NAME
  mp3loop --- directory mp3 loop player with remote control

SYNOPSIS
  mp3loop [-m] [-v VOL] [-s WHEN] [-n [N]] [-p [N]] [-e|-r] [--] [TARGET]
  mp3loop -h | --help

DESCRIPTION
  mp3loop plays the mp3 files of one directory in sequence order,
  wrapping to the first track after the last, until a stop
  condition. Invoked while a loop is playing, or with -r, it acts
  as a remote: it rewrites the state the loop runs on, signals the
  loop, prints the resulting plan, and returns.

  The player reads its state at each track boundary. A setting
  changed by a remote, or by editing a state file directly, takes
  effect when the current track ends; -e moves the boundary to now.

  mp3loop drives either a local workstation or a headless
  network-attached player: a host with music storage, wired to an
  amplifier and speakers, and commanded from a workstation over
  ssh, for example: ssh player mp3loop -v 40
  Amplifier standby/on relay control is a planned feature.

OPTIONS
  -m       Memory only; see MEMORY ONLY.
  -v VOL   Volume 1-100. 0 stops the loop at the next boundary.
  -s WHEN  Latest time a track may start, checked at each boundary.
             HEX    absolute unix seconds, 1-8 hex digits, right-
                    padded with 0: 6ace and 6ace0000 are equal
             +N[u]  N from now, integer, unit s m h d w (m default)
             0      clear the stop time
           A time already past is an error.
  -n [N]   Skip N tracks (default 1); N may be negative.
           After the current track: -n skips the next track, -n0
           continues normally, -n -1 replays the current track.
           With -e, counting starts at the current track: -n plays
           the next track now, -n0 restarts the current one, -n -1
           plays the previous one. With a TARGET: TARGET plus N.
           Each remote -n replaces the previous one; -n0 revokes it.
  -p [N]   Preview N tracks before each play (default 10; 0 off).
           As a remote, also prints the queue and directory in
           this terminal.
  -e       Apply now: end the current play. With no other option
           or TARGET, the loop stops. Otherwise the loop resumes at
           once under the new state; a settings-only change
           restarts the current track.
  -r       Apply after the current track. Implied for any remote
           call. With no loop playing, records the state for the
           next start without playing.
  -h       Usage summary.
  --help   This manual.
  Values attach or follow: -v55, -v 55. An integer following -n
  (negative too) or -p is taken as its value; put -- before a
  numeric TARGET there: mp3loop -n 1 -- 5

TARGET
  DIR         first track of DIR
  FILE        that file, by relative or absolute path
  PATH/FRAG   first track sorting at or after FRAG in PATH
  FRAG        as PATH/FRAG, in the last played directory
  (none)      start: resume at the last played track, or at a
              request still pending when the loop stopped
              remote: keep the current sequence
  An existing file always wins over a FRAG with the same name.

PRECEDENCE
  A command line option wins. Otherwise a setting comes from its
  state file, and only then from its default:
    volume    88 when the file is missing or invalid; a stored 0
              refuses the start until -v is given
    stop      none
    preview   0 (off)
    position  a start with no TARGET and no stored position is a
              usage error

ORDER
  Names sort in the C locale. The sequence id is the alphanumeric
  prefix that ends at the first comma; tracks with equal ids play
  in name order. A name without an id draws a warning and sorts by
  its whole name. Names that begin with 0 or y are not played.

DISPLAY
  Before each play, from top to bottom:
    the preview, furthest track first, next track last
    name warnings
    the realpath of the directory
    the current track, its duration and volume

NAME SAFETY
  warn, play:   space, and any character outside [A-Za-z0-9._,+^-]
                that is not in the error class
  error, skip:  ' " ` ( ) { } [ ] ; # $ @ ! % * ? & | < > \
                non-printable characters (CR, TAB, LF ...), non-ASCII
  Both classes are logged to ~/0/v/mp3loop_err, one line per name,
  with error characters replaced by X and spaces by _:
    6ace01f3-20261012_140000 warn /abs/dir/a14,blue_moon.mp3
    6ace01f3-20261012_140000 error /abs/dir/a15,rock_X_roll.mp3
  A directory path in the error class is logged the same way and
  stops with status 2.

MEMORY ONLY (-m)
  For a player on removable flash media, or any read-only mount.
  The player keeps all state in memory: it reads and writes no
  state file and no log, needs a TARGET, and takes -v -s -p from
  the command line or their defaults. It ignores hangup, so it
  keeps playing after an ssh session ends; its messages go to the
  terminal, or to /dev/null once the terminal is gone. A remote
  call can then only signal it: -e stops it, -n -e plays the next
  track now; any other request is refused with status 2. The
  remote reports what ps shows: pid, current track and volume.

REMOTE OUTPUT
  playing: pid 4242 /abs/dir/a12,foo.mp3
  after: vol 40; next a15,bar.mp3; stop 6ace0000 (date)
  The second line begins "now:" when -e applies. For a memory
  only player:
  playing: pid 4242 memory /abs/dir/a12,foo.mp3 (vol 40)
  now: next

STATE (~/0/v)
  mp3loop_pos      current track, written at each play; another
                   path, or a second line (a remote writes request),
                   is a request to play from there
  mp3loop_vol      volume; 0 stops at the boundary
  mp3loop_stop     latest track start, 8 hex digits; empty or 0
                   means none, and a stop resets it to 0
  mp3loop_stopped  time and cause of the last stop
  mp3loop_preview  preview count
  mp3loop_list     sorted list, rewritten when the directory changes
  mp3loop_pid      player pid and start time, checked before any
                   signal is sent, then the current track
  mp3loop_err      log of names in the warn and error classes
  The files hold the current or programmed state, or the state at
  the last stop. None is read or written with -m.

SIGNALS
  USR1  reload state now (sent by -e with options or TARGET);
        a memory only player plays the next track
  TERM  stop now (sent by -e alone)
  INT   Ctrl-C in the player terminal: stop now
  HUP   the player terminal closed: stop now; ignored with -m

EXIT STATUS
  0    stopped by volume 0, stop time, or -e; or remote success
  1    player error
  2    usage error, unsafe directory path, stored volume 0
       without -v, or a request a memory only player cannot take
  3    no playable track
  129  hangup (HUP)
  130  interrupted (INT)

DEPENDENCIES
  ffplay and ffprobe, looked up through PATH when the function
  runs. An alias (for example ffplay8) takes effect only when it is
  defined before mp3loop is sourced, and never in a non-interactive
  ssh call; on a headless player use a PATH entry or a symlink
  named ffplay instead. Also awk, sed, stat (GNU or BSD), ps.

EXAMPLES
  mp3loop ~/music/set1      start at the first track
  mp3loop -v 40             remote: volume 40 after this track
  mp3loop -v 40 -e          remote: restart this track at 40
  mp3loop -n -e             remote: next track now
  mp3loop -n -2 -e          remote: previous track now
  mp3loop -s +90            remote: start no track after 90 minutes
  mp3loop -e                remote: stop now
  mp3loop -r -s 6ace        not playing: when next started, start no
                            track after 6ace0000
  ssh player 'mp3loop -m ~/music/set1 >/dev/null 2>&1 &'
                            headless start, no writes, survives logout
eof

    # --- options: values attach or follow; a following value for -n (signed) or -p only when an integer
    o_vol='' o_stop='' o_skip='' o_prev='' o_mode='' o_mem='' stop_x='' mem=''
    while [ $# -gt 0 ] ; do
        case "$1" in
        -h) usage ; exit 0 ;;
        --help|-help) manual ; exit 0 ;;
        -m) o_mem=1 ; shift ;;
        -v) [ $# -ge 2 ] || usage_err "-v needs a value" ; o_vol="$2" ; shift 2 ;;
        -v*) o_vol="${1#-v}" ; shift ;;
        -s) [ $# -ge 2 ] || usage_err "-s needs a value" ; o_stop="$2" ; shift 2 ;;
        -s*) o_stop="${1#-s}" ; shift ;;
        -n) isint "${2-}" && { o_skip="$2" ; shift 2 ;} || { o_skip=1 ; shift ;} ;;
        -n*) o_skip="${1#-n}" ; shift ;;
        -p) isnum "${2-}" && { o_prev="$2" ; shift 2 ;} || { o_prev=10 ; shift ;} ;;
        -p*) o_prev="${1#-p}" ; shift ;;
        -e|-r) [ "$o_mode" -a "$o_mode" != "${1#-}" ] && usage_err "-e and -r exclude each other"
            o_mode="${1#-}" ; shift ;;
        --) shift ; break ;;
        -?*) usage_err "unknown option '$1'" ;;
        *) break ;;
        esac
      done
    [ $# -le 1 ] || usage_err "one TARGET only, got '$*'"
    target="${1-}"
    [ "$o_vol" ] && { isvol "$o_vol" || usage_err "volume '$o_vol' is not 0-100" ; o_vol=$(( 10#$o_vol )) ;}
    [ "$o_skip" ] && { isint "$o_skip" || usage_err "skip '$o_skip' is not an integer"
        [[ $o_skip == -* ]] && o_skip=$(( -10#${o_skip#-} )) || o_skip=$(( 10#$o_skip )) ;}
    [ "$o_prev" ] && { isnum "$o_prev" || usage_err "preview '$o_prev' is not a count" ; o_prev=$(( 10#$o_prev )) ;}
    [ "$o_stop" ] && { stopparse "$o_stop" || exit 2 ;}
    [ "$o_mem" -a "$o_mode" = r ] && usage_err "-m and -r exclude each other"
    any="$o_vol$o_stop$o_skip$o_prev$target" # anything to apply beyond -e/-r

    # --- live player: pid file (pid alive, start time unchanged), else a memory only beacon in ps
    live='' pcur='' mlive='' mcur='' mvol=''
    [ -f "$pid_f" ] && { { read -r x ; read -r pcur ;} <"$pid_f" || :
        lpid="${x%% *}" lst="${x#* }"
        isnum "$lpid" && kill -0 "$lpid" 2>/dev/null \
          && read -r x < <(ps -o lstart= -p "$lpid" 2>/dev/null) && [ "$x" = "$lst" ] && live="$lpid" ;}
    [ "$live" ] || { mapfile -t P < <(ps -A -ww -o pid= -o ppid= -o args= 2>/dev/null)
        ps_re='^ *[0-9]+ +([0-9]+) +(.*)$' # pid, ppid, args (no here-string: no temp file)
        for x in "${P[@]}" ; do [[ $x =~ $ps_re ]] || continue ; pp="${BASH_REMATCH[1]}" a="${BASH_REMATCH[2]}"
            [[ $a == mp3loop_memory\ * ]] && (( pp > 1 )) && kill -0 "$pp" 2>/dev/null && mlive="$pp"
          done
        [ "$mlive" ] && for x in "${P[@]}" ; do [[ $x =~ $ps_re ]] || continue ; pp="${BASH_REMATCH[1]}" a="${BASH_REMATCH[2]}"
            [ "$pp" = "$mlive" ] && [[ $a =~ -window_title\ mp3loop\ -volume\ ([0-9]+)\ (.*)$ ]] \
              && mvol="${BASH_REMATCH[1]}" mcur="${BASH_REMATCH[2]}"
          done ;}

    # --- remote to a memory only player: signals only (TERM stop, USR1 next)
    [ "$mlive" ] && {
        echo "playing: pid $mlive memory ${mcur:-(between tracks)} (vol ${mvol:-?})"
        [ "$o_mode" = e -a -z "$o_vol$o_stop$o_prev$target" ] && [ -z "$o_skip" -o "$o_skip" = 1 ] \
          || { chkwrn "mp3loop : memory only player takes only -e or -n -e (6acd6601)" ; exit 2 ;}
        [ "$o_skip" ] && { kill -USR1 "$mlive" ; echo "now: next" ;} || { kill -TERM "$mlive" ; echo "now: stop" ;}
        exit 0 ;}

    # --- TARGET to dir and mark; FRAG uses the playing (else last played) directory, never with -m
    here='' ; [ "$o_mem" ] || { get "$pos_f" ; here="${val%/*}" ;} ; [ "$live" ] && here="${pcur%/*}"
    dir='' mark=''
    [ "$target" ] && {
        [ -d "$target" ] && { dirok "$target" || exit 2 ;} \
          || { [ -f "$target" ] || [[ $target == */* ]] \
                && { x=. ; [[ $target == */* ]] && x="${target%/*}" ; dirok "${x:-/}" || exit 2
                    mark="${target##*/}" ;} \
                || { [ "$here" ] || usage_err "FRAG '$target' and no last played directory"
                    dirok "$here" || exit 2 ; mark="$target" ;} ;}
        dir="$rdir" ;}

    # --- remote: reprogram the live player, signal for -e, print the plan
    [ "$live" ] && {
        [ "$o_mem" ] && usage_err "-m starts a player; this remote would write state"
        [ "$pcur" ] || { chkerr "mp3loop : player $live has no current track (6acd4f09)" ; exit 1 ;}
        tdir="$dir" ; dir="${pcur%/*}" ; scan
        (( n )) || { chkerr "mp3loop : no playable track in '$dir' (6acd4f0a)" ; exit 3 ;}
        locate "${pcur##*/}" ; ci=$idx
        getpos ; req="$val" ; o_pos=''
        # base: what plays at the boundary with no -n (-e: the current track, else the next)
        [ "$o_mode" = e ] && ni=$ci || ni=$(( (ci + 1) % n ))
        [ "$tdir" ] && { dir="$tdir" ; scan ; locate "$mark" ; ni=$idx ; o_pos=1 ;} \
          || { [ -z "$o_skip" ] && [ "$req" ] && [ "$val2" -o "$req" != "$pcur" ] && x="${req%/*}" && dirok "${x:-/}" 2>/dev/null \
                && { dir="$rdir" ; scan ; locate "${req##*/}" ; ni=$idx ;} ;} # pending request kept
        (( n )) || { chkerr "mp3loop : no playable track in '$dir' (6acd4f0a)" ; exit 3 ;}
        [ "$o_skip" ] && { wrap "ni + o_skip" ; ni=$idx ; o_pos=1 ;} # replaces any pending request
        [ "$o_vol" ] && put "$vol_f" "$o_vol"
        [ "$o_stop" ] && put "$stop_f" "$stop_x"
        [ "$o_prev" ] && put "$prev_f" "$o_prev"
        [ "$o_pos" ] && put "$pos_f" "$dir/${L[ni]}"$'\n'request
        next="${L[ni]}"
        echo "playing: pid $live $pcur"
        [ "$o_mode" = e ] && { [ "$any" ] && { kill -USR1 "$live" ; plan now ;} \
                                       || { kill -TERM "$live" ; echo "now: stop" ;} ;} \
                          || plan after
        [ "$o_prev" ] && { x=$o_prev ; (( x > n )) && x=$n ; preview "$x" "$ni" ; echo "$dir" ;}
        exit 0 ;}

    # --- no player: start point from TARGET, else the stored position (hint; not with -m)
    [ "$dir" -o "$o_mem" ] || { get "$pos_f"
        [ "$val" ] && { dirok "${val%/*}" && dir="$rdir" mark="${val##*/}" ;} ;}

    # --- -r with no player: record state for the next start, play nothing
    [ "$o_mode" = r ] && {
        [ "$o_vol" ] && put "$vol_f" "$o_vol"
        [ "$o_stop" ] && put "$stop_f" "$stop_x"
        [ "$o_prev" ] && put "$prev_f" "$o_prev"
        next='' n=0
        [ "$dir" ] && { scan ; (( n )) && { locate "$mark"
            [ "$o_skip" ] && wrap "idx + o_skip"
            next="${L[idx]}" ; [ "$target$o_skip" ] && put "$pos_f" "$dir/$next" ;} ;}
        echo "playing: none"
        plan "next start"
        [ "$o_prev" ] && (( n )) && { x=$o_prev ; (( x > n )) && x=$n ; preview "$x" "$idx" ; echo "$dir" ;}
        exit 0 ;}

    # --- start: settings by precedence (option, state file, default); -m: option, default
    [ "$dir" ] || { [ "$o_mem" ] && usage_err "-m needs a TARGET" ; usage_err "no TARGET and no last played track" ;}
    stop_e=0
    [ "$o_mem" ] && { vol="${o_vol:-88}" prev="${o_prev:-0}"
        [ "$stop_x" ] && stop_e=$(( 16#$stop_x )) ; : ;} \
      || { [ "$o_vol" ] && vol="$o_vol" || { get "$vol_f" ; vol="$val"
            isvol "$vol" || { chkwrn "mp3loop : stored volume '$vol' invalid, using 88 (6acd4f0b)" ; vol=88 ;}
            (( 10#$vol )) || usage_err "stored volume is 0, give -v to start" ;}
        put "$vol_f" "$(( 10#$vol ))"
        [ "$o_stop" ] && put "$stop_f" "$stop_x" || { get "$stop_f" ; now
            [[ $val =~ ^[0-9a-f]{8}$ ]] && (( 16#$val && 16#$val <= now )) \
              && { chkwrn "mp3loop : stored stop time $val is past, ignored (6acd4f0c)" ; put "$stop_f" 0 ;} ;}
        [ "$o_prev" ] && put "$prev_f" "$o_prev" ;}
    mem="$o_mem" # from here put and logname write nothing with -m
    scan w ; (( n )) || { stamp ; put "$stopped_f" "$stamp no playable track"
        chkerr "mp3loop : no playable track in '$dir' (6acd4f0a)" ; exit 3 ;}
    locate "$mark" ; [ "$o_skip" ] && wrap "idx + o_skip"

    # --- player: one track per pass; the boundary at the top reads all state
    halt () { stamp ; put "$stopped_f" "$stamp $1" ; chkwrn "mp3loop : stopped, $1 (6acd4f0d)" ; exit "$2" ;}
    sig='' child='' beacon='' intr='' first=1 cur='' tty1='' tty2=''
    trap '[ "$child" ] && kill "$child" 2>/dev/null ; [ "$beacon" ] && kill "$beacon" 2>/dev/null' EXIT
    trap 'sig=USR1 ; [ "$child" ] && kill "$child" 2>/dev/null' USR1
    trap 'sig=TERM ; [ "$child" ] && kill "$child" 2>/dev/null' TERM
    trap 'sig=INT ; [ "$child" ] && kill "$child" 2>/dev/null' INT
    # -m: hangup and broken pipe ignored (children inherit), ps beacon; else pid file guard
    [ "$mem" ] && { trap '' HUP PIPE ; [ -t 1 ] && tty1=1 ; [ -t 2 ] && tty2=1
            ( exec -a mp3loop_memory sleep 2147483647 ) </dev/null >/dev/null 2>&1 & beacon=$! ;} \
      || { trap 'sig=HUP ; [ "$child" ] && kill "$child" 2>/dev/null' HUP
            me=$BASHPID # expand here: inside <( ) BASHPID is that subshell, not the player
            read -r lstart < <(ps -o lstart= -p "$me") ;}
    while : ; do sig='' adv=''
        # -m: once the terminal is gone, messages go to /dev/null
        [ "$mem" ] && { [ "$tty1" ] && ! [ -t 1 ] && { exec >/dev/null ; tty1='' ;}
                        [ "$tty2" ] && ! [ -t 2 ] && { exec 2>/dev/null ; tty2='' ;} ;}
        # boundary: settings from state files (-m: kept in memory), then stop conditions
        [ "$mem" ] || { get "$vol_f" ; vol="$val"
            isvol "$vol" || { chkwrn "mp3loop : volume '$vol' invalid, using 88 (6acd4f0b)" ; vol=88 ; put "$vol_f" 88 ;}
            get "$stop_f" ; [[ $val =~ ^[0-9a-f]{8}$ ]] && stop_e=$(( 16#$val )) || stop_e=0
            get "$prev_f" ; isnum "$val" && prev=$(( 10#$val )) || prev=0 ;}
        vol=$(( 10#$vol )) ; (( vol )) || halt "volume 0" 0
        (( stop_e )) && { now ; (( now >= stop_e )) && { put "$stop_f" 0 ; printf -v x '%08x' "$stop_e"
                halt "stop time $x" 0 ;} ;}
        # boundary: position; -m always advances; else a request line or another
        # path in pos is a request, otherwise advance, or replay after -e
        [ "$first" ] || { [ "$mem" ] && adv=1 || { getpos
            [ "$val" ] && [ "$val2" -o "$val" != "$cur" ] && { d="${val%/*}"
                    dirok "${d:-/}" && { [ "$rdir" = "$dir" ] || { dir="$rdir" ; scan w ;}
                        (( n )) || halt "no playable track" 3 ; locate "${val##*/}" ;} \
                      || { chkwrn "mp3loop : request '$val' ignored (6acd4f0e)" ; [ "$intr" ] || adv=1 ;} ;} \
              || { [ "$intr" ] || adv=1 ;} ;} ;}
        intr='' first=''
        # directory mtime changed or track vanished: rescan, relocate by name
        mtime "$dir"
        [ "$m" != "$dmt" -o ! -f "$dir/${L[idx]}" ] && { x="${L[idx]}" ; scan w
            (( n )) || halt "no playable track" 3 ; locate "$x" ; (( exact )) || adv='' ;}
        [ "$adv" ] && idx=$(( (idx + 1) % n ))
        # record the current track: pos (one line) and pid file; none with -m
        cur="$dir/${L[idx]}"
        [ "$mem" ] || { put "$pos_f" "$cur" ; put "$pid_f" "$BASHPID $lstart"$'\n'"$cur" ;}
        # display: preview far to near, warnings, directory, current track
        x=$prev ; (( x > n - 1 )) && x=$(( n - 1 )) ; preview "$x" $(( idx + 1 ))
        for x in "${W[@]}" ; do chkwrn "$x" ; done ; W=()
        echo "$dir"
        tput bold 2>/dev/null ; chktrue "${L[idx]}" ; tput sgr0 2>/dev/null
        read -r dur < <(ffprobe -hide_banner -loglevel info "$cur" 2>&1 \
            | sed -e '/Duration/!d' -e 's/,.*//' -e 's/.* //') || :
        echo " $(hms2sec "$dur") sec, vol $vol"
        touch -a "$cur" # since mac does not update atime, cf APFS_FEATURE_STRICTATIME
        # play in the background so traps run during wait; INT is ignored by
        # background children, the trap kills ffplay instead; -window_title
        # marks the process for a memory only remote (ps)
        ffplay -hide_banner -stats -autoexit -loglevel error -nodisp -window_title mp3loop \
            -volume "$vol" "$cur" </dev/null &
        child=$! ; [ "$sig" ] && kill "$child" 2>/dev/null # signal landed before the child existed
        while wait "$child" ; rc=$? ; kill -0 "$child" 2>/dev/null ; do : ; done
        child=''
        case "$sig" in
        TERM) halt "remote stop" 0 ;;
        INT) halt "interrupt" 130 ;;
        HUP) halt "hangup" 129 ;;
        USR1) intr=1 ;;
        *) (( rc )) && halt "player error $rc" 1 ;;
        esac
      done
) # mp3loop 6acd6600-20261012_155808
