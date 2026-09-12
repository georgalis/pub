#!/usr/bin/env bash
#
cat >/dev/null <<'eof'
1 geo@AAAA:~/vcs/pub/sub _yt --ot https://youtu.be/8z7QFzDy-as?si=6zPu-z_SX4eoRxgK  /Users/geo/kdb//6/a/9/e/_yt_psych
[youtube] Extracting URL: 8z7QFzDy-as
[youtube] 8z7QFzDy-as: Downloading webpage
[youtube] 8z7QFzDy-as: Downloading visionos player API JSON
[youtube] 8z7QFzDy-as: Downloading m3u8 information
[info] 8z7QFzDy-as: Downloading subtitles: en
[info] 8z7QFzDy-as: Downloading 1 format(s): 616+251-20
[info] Writing video subtitles to: /Users/geo/kdb//6/a/9/e/_yt_psych/foli/6a9e/ec28/6a9eec28,I_Used_to_Be_a_Scientist._Now_I_m_a_Substitute_Teacher_What_I_Learned_About_Status-20260901_^8z7QFzDy-as.en.vtt
ERROR: Unable to download video subtitles for 'en': HTTP Error 429: Too Many Requests
>>> _yt : json not found (695f500d)
1 geo@AAAA:~/vcs/pub/sub _yt --ot https://youtu.be/8z7QFzDy-as  /Users/geo/kdb//6/a/9/e/_yt_psych
[youtube] Extracting URL: 8z7QFzDy-as
[youtube] 8z7QFzDy-as: Downloading webpage
[youtube] 8z7QFzDy-as: Downloading visionos player API JSON
[youtube] 8z7QFzDy-as: Downloading m3u8 information
[info] 8z7QFzDy-as: Downloading subtitles: en
[info] 8z7QFzDy-as: Downloading 1 format(s): 616+251-20
[info] Writing video subtitles to: /Users/geo/kdb//6/a/9/e/_yt_psych/foli/6a9e/ec47/6a9eec47,I_Used_to_Be_a_Scientist._Now_I_m_a_Substitute_Teacher_What_I_Learned_About_Status-20260901_^8z7QFzDy-as.en.vtt
[download] Destination: /Users/geo/kdb//6/a/9/e/_yt_psych/foli/6a9e/ec47/6a9eec47,I_Used_to_Be_a_Scientist._Now_I_m_a_Substitute_Teacher_What_I_Learned_About_Status-20260901_^8z7QFzDy-as.en.vtt
[download] 100% of  112.04KiB in 00:00:00 at 282.52KiB/s
[info] Writing video metadata as JSON to: /Users/geo/kdb//6/a/9/e/_yt_psych/foli/6a9e/ec47/6a9eec47,I_Used_to_Be_a_Scientist._Now_I_m_a_Substitute_Teacher_What_I_Learned_About_Status-20260901_^8z7QFzDy-as.info.json
><> /Users/geo/kdb//6/a/9/e/_yt_psych/foli/6a9e/ec47/6a9eec47,I_Used_to_Be_a_Scientist._Now_I_m_a_Substitute_Teacher_What_I_Learned_About_Status-20260901_^8z7QFzDy-as.en.vtt.txt
 geo@AAAA:~/vcs/pub/sub mv /Users/geo/kdb//6/a/9/e/_yt_psych/foli/6a9e/ec47/6a9eec47,I_Used_to_Be_a_Scientist._Now_I_m_a_Substitute_Teacher_What_I_Learned_About_Status-20260901_^8z7QFzDy-as.en.vtt.txt /Users/geo/kdb//6/a/9/e/_yt_psych/
eof
# sanitize fails: https://www.youtube.com/watch?v=p-vXirtY0ys&t=49s&pp=0gcJCRsMAYcqIYzv
#
# (c) 2026 George Georgalis <george@galis.org> unlimited use with this notice
# rev 6a777dfb 20260808 120531 PDT Sat 12:05 PM 8 Aug 2026 --- plan composition uplift
# rev 69c9bcdb 20260329 165923 PDT Sun 04:59 PM 29 Mar 2026 --- playlist management
# rev 69befaeb 20260321 130915 PDT Sat 01:09 PM 21 Mar 2026 --- playlist management
# rev 695f5300 20260107 224728 PST Wed 10:47 PM 7 Jan 2026 --- yt-dlp wrapper suite for media download and organization
# synthesized from canonical forms of audio tools
# revision: https://github.com/georgalis/pub/blob/7520c3c0e4301e8698e64d669f1f8df4b4ecbe06/sub/fn.bash#L377
# original: Feb 4, 2020 https://github.com/georgalis/pub/commit/0fa259132d6ea282c012115138727ab780b47a56
#
# 6a777dfb design: every option composes one execution plan; info.json is
# always captured; -t -v add features to the default (audio) plan, while
# --to --vo --jo suppress the audio default and run only the named
# feature(s) (combinable). Staging *.info.json.txt files are downstream
# processing bookmarks: created in the pending location (single-track: $d;
# playlist aggregate: $d beside foli/), moved beside their info.json data
# by the downstream process on completion---location encodes status.
# Playlist per-track staging lives in the folio permanently. Staging files
# are never overwritten: name collisions index the xs ({xs}2, {xs}3, ...).
#
# Directory Architecture:
#   $d/                                    root (default ./)
#   $d/00{xs},{template}.info.json.txt     f2rb2mp3 staging data (single track, pending)
#   $d/00{xs},{template}.{lang}.srt.txt    transcript beside pending staging (single track)
#   $d/@/_^{id}.{ext}                      hardlinked audio (programmatic access, audio only)
#   $d/foli/{xs_maj}/{xs_min}/             folio per download timestamp
#     {xs},{template}.{ext}                original media + metadata + thumbnails + srt
#     {xs},{template}.com.yml              comment yaml (unless --nyc)
#   Playlist: {xs}{playlist_index},{template}.{ext} in shared folio
#     {xs},{playlist_title}-^{playlist_id}.meta.json   playlist metadata (single fetch, entries stripped)
#     {xs}{n},{template}.info.json.txt         per-track staging (in folio, sans 00, permanent)
#     $d/00{xs}0,{playlist_title}-^{playlist_id}.list.txt   aggregated staging (pending)
#     {xs},{playlist_title}-^{playlist_id}.unavail.yml   unavailable track manifest
#     Retry: reuses existing foli and its xs; list.txt collisions index the xs
#
# Subtitles: -t runs a dedicated srt pass (upstream srt preferred,
#   converted from best otherwise); no vtt artifacts. The transcript
#   carries a meta header and inline chapter markers, and follows the
#   staging convention: playlist -> folio sans 00, single -> $d with 00
# xs derivation: ts function (hex epoch), header via ts_header
# Timestamps: original files (media, subs, thumbnails) use epoch mtime,
#             derived files (json, txt, yml) use ts mtime
# Duplicate detection root: $_yt_root (default $d/..), for both single-track
#   media and playlist marker search; find prunes only "-name tmp"
# Retry: failed ytdl invocations clean partials and retry, $_yt_tries
#   attempts total (default 3) after $_yt_delay seconds (default 15)
# Dependencies: $ytdl (yt-dlp), ffmpeg (sub convert, video merge), ts, jq, yq, nbsed, iconv, chkerr chkwrn chktrue

# --- portable epoch date (GNU: date -d @epoch; BSD/Darwin: date -r epoch)
date --version &>/dev/null \
  && { _yt_dfmt='-d' ; _yt_at='@' ;} \
  || { _yt_dfmt='-r' ; _yt_at='' ;}
_yt_date () { date "$_yt_dfmt" "${_yt_at}$1" "$2" ;} # _yt_date EPOCH +FMT

# =============================================================================
# _yt_dl --- retried ytdl invocation with output filter and partial cleanup
# =============================================================================

_yt_dl () { # run ytdl argv with noise filter; on failure clean partials, delay, retry
  # dynamic scope: $dx (session folio) bounds partial-download cleanup
  local try=1 tries="${_yt_tries:-3}" delay="${_yt_delay:-15}" rc=
  while : ; do
    "$@" 2>&1 | { nbsed -l '/^\[youtube\] Sleeping/d;/API JSON reply thread/d;/replies API JSON page/d;/Downloading video thumbnail/d;/Video Thumbnail .* does not exist/d' || true ;}
    rc="${PIPESTATUS[0]}" ; [ "$rc" -eq 0 ] && return 0
    [ "$try" -ge "$tries" ] && { chkerr "$FUNCNAME : ytdl exit $rc after $try attempts (6a777d01)" ; return "$rc" ;}
    chkwrn "$FUNCNAME : ytdl exit $rc, cleaning partials, attempt $((try+1))/$tries in ${delay}s (6a777d02)"
    # partial artifacts only---never pre-existing data (name class hard coded)
    [ -d "${dx:-}" ] && { find "$dx/" -maxdepth 1 \
      \( -name '*.part' -o -name '*.part-Frag*' -o -name '*.ytdl' \) \
      -exec rm -f {} + 2>/dev/null || : ;} || :
    sleep "$delay" ; try=$((try+1))
  done ;} # _yt_dl 6a777d00

_yt_have () { # track complete in folio: _yt_have FOLIO ID [WANT_MEDIA]
  # keyed on id: flat playlist data carries no upload_date to match filenames
  # note: read -d '' always signals at eof, so test the variable, not the read
  local fdx="${1:?}" tid="${2:?}" want_media="${3:-}" hit=
  read -d '' hit < <(find "$fdx/" -maxdepth 1 -name "*_^${tid}.info.json" 2>/dev/null) || :
  [ "$hit" ] || return 1
  [ "$want_media" ] || return 0
  hit=
  read -d '' hit < <(find "$fdx/" -maxdepth 1 -name "*_^${tid}.*" \
    \( -name "*.opus" -o -name "*.m4a" -o -name "*.mp3" -o -name "*.webm" \) 2>/dev/null) || :
  [ "$hit" ] || return 1
  return 0 ;} # _yt_have 6a777d50

_yt_rmdir_empty () { # remove session folio dirs if empty (failure cleanup)
  rmdir "${1:?}" 2>/dev/null || : ; rmdir "${1%/*}" 2>/dev/null || : ;} # 6a777d40

# =============================================================================
# _yt --- primary entry for yt-dlp download and organization
# =============================================================================

_yt () { # ytdl wrapper: download media, organize folio, create staging txt
  local id= d= ytdl=${ytdl:-yt-dlp} verb=${verb:-devnul}
  local opt_playlist= opt_ta= opt_nc= opt_nyc= opt_utf8= opt_no_expand=
  local do_audio=1 do_subs= do_video= do_thumbs= opt_video_res= video_req= sub_langs=
  local xs= xs_date= xs_time= dx= existing=
  local ts_touchtime= epoch= epoch_touchtime=
  local playlist_id= playlist_title= safe_title= opt_retry= retry_items= existing_xs=
  local pl_json= pl_entries=()
  local OPTIND=1 OPTARG= opt=

  # --- help dispatch
  [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] && { _yt_help ; return 0 ;}

  # --- pre-scan for long options before getopts ("--" passes the rest verbatim)
  local args=() arg= sawdd= vpend=
  for arg in "$@" ; do
    [ "$sawdd" ] && { args+=("$arg") ; continue ;}
    [ "$vpend" ] && { vpend=
      [[ "$arg" =~ ^[0-9]+$ ]] && { video_req="$arg" ; continue ;} || : ;} # non-numeric: default set, arg falls through
    case "$arg" in
      --to) do_subs=1 ; do_audio= ;;
      --vo) do_video=1 ; do_audio= ;;
      --jo) do_audio= ;;
      --ta) opt_ta=1 ; do_subs=1 ;;
      --video=*) do_video=1 ; video_req="${arg#*=}" ;;
      --video) do_video=1 ; vpend=1 ;; # numeric next arg is RES, else default set
      --nc) opt_nc=1 ;;
      --nyc) opt_nyc=1 ;;
      --help) _yt_help ; return 0 ;;
      --) sawdd=1 ; args+=("$arg") ;;
      --*) chkerr "$FUNCNAME : unknown option '$arg' (6a777d10)" ; return 1 ;;
      *) args+=("$arg") ;;
    esac
  done

  # --- getopts for short options (allows -tv, -vt, etc)
  set -- "${args[@]}"
  while getopts ":ptvVjuxh" opt ; do
    case "$opt" in
      p) opt_playlist=1 ;;
      t) do_subs=1 ;;
      v) do_video=1 ;;         # resolution from default set (see video_req)
      V) do_video=1 ; video_req=max ;;
      j) : ;;                  # info.json always captured---default alias
      u) opt_utf8=1 ;;
      x) opt_no_expand=1 ;;
      h) _yt_help ; return 0 ;;
      :) chkerr "$FUNCNAME : option -$OPTARG requires argument (695f5001)" ; return 1 ;;
      \?) chkerr "$FUNCNAME : unknown option '-$OPTARG', use -- before ids with leading dash (6a777d11)" ; return 1 ;;
    esac
  done
  shift $((OPTIND - 1))

  # --- parse positionals
  while [ $# -gt 0 ] ; do
    [ -z "$id" ] && { id="$1" ; shift ; continue ;}
    [ -z "$d" ] && { d="$1" ; shift ; continue ;}
    chkerr "$FUNCNAME : unexpected arg '$1' (695f5003)" ; return 1
  done

  # --- input validation
  [ "$id" ] || { chkerr "$FUNCNAME : no id? (695f5004)" ; return 1 ;}
  [[ "$id" =~ ^[A-Za-z0-9._/:?=\&-]+$ ]] || { chkerr "$FUNCNAME : unsafe id chars '$id' (695f5005)" ; return 1 ;}
  read id < <(sed -e 's/[?&]si=[[:alnum:]_-]\{16\}[&]*//' -e 's/\?$//' <<<"$id") # strip trackers
  d="${d:-.}"
  [ -d "$d" ] || mkdir -p "$d" || { chkerr "$FUNCNAME : invalid dir '$d' (695f5006)" ; return 1 ;}

  # --- duplicate detection root (single-track media and playlist markers)
  local _yt_root="${_yt_root:-${d}/..}"
  [ -d "$_yt_root" ] || _yt_root="${d}/.."

  # --- timestamp via ts function
  # ts output: 695f4d58 20260107 222320 PST Wed 10:23 PM  7 Jan 2026
  local ts_out= ts_header=
  ts_out=$(ts) || { chkerr "$FUNCNAME : ts function failed (695f5008)" ; return 1 ;}
  read xs xs_date xs_time _ <<<"$ts_out"
  ts_header="$ts_out"
  # construct touchtime CCYYMMDDhhmm.SS from xs_date (CCYYMMDD) and xs_time (hhmmSS)
  ts_touchtime="${xs_date}${xs_time:0:4}.${xs_time:4:2}"

  # --- @ dir setup (needed for all paths including retry)
  [ -d "$d/@" ] || mkdir -p "$d/@" || { chkerr "$FUNCNAME : cannot mkdir '$d/@' (695f5009)" ; return 1 ;}

  # --- pre-check: playlist resolution (single json fetch) or single-track id resolution
  [ "$opt_playlist" ] && {
    read -rd '' pl_json < <($ytdl --flat-playlist --no-warnings --ignore-config \
      --dump-single-json -- "$id") || :
    [ "$pl_json" ] || { chkerr "$FUNCNAME : no playlist data from '$id' (695f5017)" ; return 1 ;}
    read -r playlist_id < <(jq -r '.id // empty' <<<"$pl_json") || :
    read -r playlist_title < <(jq -r '.title // empty' <<<"$pl_json") || :
    [ "$playlist_id" ] || { chkerr "$FUNCNAME : no playlist_id from '$id' (6a777d12)" ; return 1 ;}
    read safe_title < <(printf '%s' "$playlist_title" \
      | tr -cs 'A-Za-z0-9_.-' '_' | sed 's/__*/_/g;s/^_//;s/_$//')
    # entries reused for retry scan and post-download unavailability report;
    # flat extraction omits upload_date, so presence is keyed on id alone and
    # availability on the placeholder title yt-dlp returns for dead entries
    readarray -t pl_entries < <(jq -r '
      [.entries[]?] | to_entries[] |
      "\(.value.playlist_index // (.key + 1))\t\(.value.id // "")\t" +
      (if ((.value.title // "") | test("^\\[(private|deleted|unavailable)"; "i"))
        then "u" else "" end)' <<<"$pl_json")
    # duplicate check against marker files under _yt_root
    read -d '' existing < <(find "$_yt_root" -name tmp -prune -false \
      -o -name "*-^${playlist_id}.meta.json" -print 2>/dev/null | sort -r) || :
    [ "$existing" ] && {
      echo "$existing"
      read -n1 -p "playlist found, (a)bort/(c)ontinue new foli/(r)esume missing? " ; echo
      case "$REPLY" in
        c) ;; # fresh download to new foli
        r) # retry missing tracks into existing foli
          existing_xs="${existing##*/}" ; existing_xs="${existing_xs%%,*}"
          local existing_dx="${existing%/*}"
          local missing_items=() unavail_items=() line= pi= tid= flag=
          local unavail_file="$existing_dx/${existing_xs},${safe_title}-^${playlist_id}.unavail.yml"
          for line in "${pl_entries[@]}" ; do
            IFS=$'\t' read pi tid flag <<<"$line"
            [ "$tid" ] || continue
            _yt_have "$existing_dx" "$tid" "$do_audio" && continue || :
            [ "$flag" = u ] && unavail_items+=("$pi:$tid") || missing_items+=("$pi")
          done
          # report unavailable tracks
          [ ${#unavail_items[@]} -gt 0 ] && {
            echo "${#unavail_items[@]} unavailable (private/deleted/geo-blocked):"
            printf '  %s\n' "${unavail_items[@]}"
            # write/update unavail manifest
            { echo "playlist_id: $playlist_id"
              echo "updated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
              echo "unavailable:"
              local ua= ; for ua in "${unavail_items[@]}" ; do
                echo "  - index: ${ua%%:*}"
                echo "    id: ${ua#*:}"
              done
            } >"$unavail_file"
            touch -t "$ts_touchtime" "$unavail_file"
          }
          [ ${#missing_items[@]} -eq 0 ] && { echo "no missing downloadable tracks" ; return 0 ;}
          printf -v retry_items '%s,' "${missing_items[@]}"
          retry_items="${retry_items%,}"
          echo "${#missing_items[@]} missing downloadable: items $retry_items"
          dx="$existing_dx" ; xs="$existing_xs" ; opt_retry=1
          ;;
        *) return 1 ;;
      esac
    } || :
  } || {
    # single-track: resolve id, check _yt_root for duplicates
    read id < <($ytdl --no-playlist --no-warnings --ignore-config --no-check-formats --geo-bypass \
      --print id -- "$id") \
      || { chkerr "$FUNCNAME : failed to load data '$id' (695f500c)" ; return 1 ;}
    read -d '' existing < <(sort -r < <(find "$_yt_root" -name tmp -prune -false \
      -o -name "*${id}*" -print 2>/dev/null)) || :
    [ "$existing" ] && { echo "$existing"
      read -p "files found, continue (N/y) "
      [ "$REPLY" = "y" ] || return 1 ;} || :
  }

  # --- video resolution plan (after id resolution, before download)
  [ "$do_video" ] && {
    case "$video_req" in
      max) opt_video_res="bestvideo+bestaudio/best" ;;
      0) [ "$opt_playlist" ] && { chkerr "$FUNCNAME : interactive resolution needs single track, set RES (6a777d13)" ; return 1 ;} || :
         $ytdl -F --no-warnings -- "$id"
         read -p "height? " video_req
         [[ "$video_req" =~ ^[1-9][0-9]*$ ]] || { chkerr "$FUNCNAME : invalid height '$video_req' (6a777d14)" ; return 1 ;}
         opt_video_res="bestvideo[height<=${video_req}]+bestaudio/best" ;;
      "") # first available from the default resolution set
         opt_video_res="bestvideo[height=1080]+bestaudio/bestvideo[height=720]+bestaudio/bestvideo[height=480]+bestaudio/bestvideo[height=360]+bestaudio/bestvideo+bestaudio/best" ;;
      *) opt_video_res="bestvideo[height<=${video_req}]+bestaudio/best" ;;
    esac
  } || :

  # --- folio setup (skip for retry, existing foli reused)
  [ "$opt_retry" ] || {
    read dx < <(nbsed "s/\(....\)/\1\//;s:^:$d/foli/:" <<<"$xs") # eg ./foli/695f/4d58
    [ -d "$dx" ] && { chkerr "$FUNCNAME : race collision '$dx' (695f500a)" ; return 1 ;} || :
    mkdir -p "$dx" || { chkerr "$FUNCNAME : cannot mkdir '$dx' (695f500b)" ; return 1 ;}
  }

  # --- execution plan: one primary pass (json always; audio default; subs on
  #     request), one video pass on request; thumbnails accompany media
  { [ "$do_audio" ] || [ "$do_video" ] ;} && do_thumbs=1 || :
  sub_langs="en-US,en-GB,en-AU,en"
  [ "$opt_ta" ] && sub_langs="en.*,${sub_langs}" || : # include auto-translated english
  local ytdl_opts=(--write-info-json --no-warnings --restrict-filenames)
  [ "$do_thumbs" ] && ytdl_opts+=(--write-thumbnail) || :
  [ "$opt_nc" ] || ytdl_opts+=(--write-comments \
    --extractor-args 'youtube:max_comments=all,all,all,all;comment_sort=newest')
  [ "$opt_playlist" ] && ytdl_opts+=(--yes-playlist) || ytdl_opts+=(--no-playlist)
  # subtitles ride the dedicated srt pass below (no vtt artifacts)
  local media_opts=() dl_items=() dl_err_mode=
  [ "$do_audio" ] && media_opts=(-f bestaudio --extract-audio) || media_opts=(--skip-download)
  [ "$opt_retry" ] && dl_items=(--playlist-items "$retry_items") || :
  [ "$opt_playlist" ] && dl_err_mode="--ignore-errors" || dl_err_mode="--abort-on-error"

  # --- output template
  local tmpl=
  [ "$opt_playlist" ] \
    && tmpl="$dx/${xs}%(playlist_index)s,%(title)s-%(upload_date)s_^%(id)s.%(ext)s" \
    || tmpl="$dx/${xs},%(title)s-%(upload_date)s_^%(id)s.%(ext)s"

  # --- playlist marker file from pre-check fetch, written before download so
  #     an interrupted session leaves a detectable partial (skip for retry)
  [ "$opt_playlist" ] && [ -z "$opt_retry" ] && {
    jq 'del(.entries)' <<<"$pl_json" >"$dx/${xs},${safe_title}-^${playlist_id}.meta.json" \
      || { chkerr "$FUNCNAME : cannot write playlist marker (6a777d1b)" ; return 1 ;}
  } || :

  # --- primary pass (retried, partials cleaned on failure)
  _yt_dl $ytdl "${ytdl_opts[@]}" "${media_opts[@]}" "$dl_err_mode" "${dl_items[@]}" \
    -o "$tmpl" -- "$id" \
    || { _yt_rmdir_empty "$dx" ; chkerr "$FUNCNAME : primary download failed (6a777d15)" ; return 1 ;}

  # --- srt pass if subs requested (upstream srt preferred, converted from
  #     best otherwise; the only subtitle artifact retained)
  [ "$do_subs" ] && {
    local srt_pl_opt=--no-playlist
    [ "$opt_playlist" ] && srt_pl_opt=--yes-playlist
    _yt_dl $ytdl --skip-download --no-warnings --restrict-filenames \
      "$srt_pl_opt" "${dl_items[@]}" \
      --write-subs --write-auto-subs --sub-langs "$sub_langs" \
      --sub-format "srt/best" --convert-subs srt \
      -o "$tmpl" -- "$id" \
      || chkwrn "$FUNCNAME : srt pass failed (6a777d1a)"
  } || :

  # --- video pass if requested (merged output, metadata already captured)
  [ "$do_video" ] && {
    local ffmpeg_loc=
    read ffmpeg_loc < <(which ffmpeg8 2>/dev/null || which ffmpeg) || :
    local vid_pl_opt=--no-playlist
    [ "$opt_playlist" ] && vid_pl_opt=--yes-playlist
    _yt_dl $ytdl --restrict-filenames --no-warnings \
      ${ffmpeg_loc:+--ffmpeg-location "$ffmpeg_loc"} \
      -f "$opt_video_res" "$dl_err_mode" "$vid_pl_opt" "${dl_items[@]}" \
      -o "$tmpl" -- "$id" \
      || chkwrn "$FUNCNAME : video pass failed (6a777d16)"
  } || :

  # --- playlist marker mtime (content written pre-download)
  [ "$opt_playlist" ] && [ -z "$opt_retry" ] && {
    touch -t "$ts_touchtime" "$dx/${xs},${safe_title}-^${playlist_id}.meta.json"
  } || :

  # --- playlist post-download: report unavailable tracks (initial download
  #     only, entries reused from pre-check fetch)
  [ "$opt_playlist" ] && [ -z "$opt_retry" ] && {
    local pd_line= pd_pi= pd_tid= pd_flag= pd_unavail=()
    for pd_line in "${pl_entries[@]}" ; do
      IFS=$'\t' read pd_pi pd_tid pd_flag <<<"$pd_line"
      [ "$pd_tid" ] || continue
      _yt_have "$dx" "$pd_tid" "$do_audio" || pd_unavail+=("$pd_pi:$pd_tid")
    done
    [ ${#pd_unavail[@]} -gt 0 ] && {
      local unavail_file="$dx/${xs},${safe_title}-^${playlist_id}.unavail.yml"
      echo "${#pd_unavail[@]} tracks unavailable (private/deleted/geo-blocked):"
      printf '  %s\n' "${pd_unavail[@]}"
      { echo "playlist_id: $playlist_id"
        echo "updated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo "unavailable:"
        local pd_ua= ; for pd_ua in "${pd_unavail[@]}" ; do
          echo "  - index: ${pd_ua%%:*}"
          echo "    id: ${pd_ua#*:}"
        done
      } >"$unavail_file"
      touch -t "$ts_touchtime" "$unavail_file"
    }
  } || :

  # --- per-track post-processing (unified iteration: N=1 for single, N=many for playlist)
  local json_files=() jf= track_id= track_ext= track_media= media_master= srt_file=
  readarray -t json_files < <(find "$dx/" -maxdepth 1 -name "*.info.json" \
    ! -name "*.meta.json" | sort)
  [ ${#json_files[@]} -gt 0 ] || { _yt_rmdir_empty "$dx"
    chkerr "$FUNCNAME : no json files in '$dx/' (695f5019)" ; return 1 ;}

  for jf in "${json_files[@]}" ; do
    # --- extract track_id from json
    read track_id < <(jq -r '.id // empty' "$jf") \
      || { chkwrn "$FUNCNAME : no id in '$jf' (695f501a)" ; continue ;}

    # --- extract epoch for original file timestamps
    read epoch < <(jq -r '.timestamp // empty' "$jf") || :
    [ "$epoch" ] && epoch_touchtime=$(_yt_date "$epoch" +"%Y%m%d%H%M.%S") \
      || epoch_touchtime="$ts_touchtime"

    # --- set ts mtime on json (derived file)
    touch -t "$ts_touchtime" "$jf"

    # --- determine audio extension from json
    read track_ext < <(jq -r '.acodec | @text' "$jf") || track_ext=
    [ "$track_ext" = "none" ] || [ "$track_ext" = "null" ] || [ -z "$track_ext" ] && {
      read -d '' track_media < <(find "$dx/" -mindepth 1 -maxdepth 1 -name "*${track_id}.*" \
        \( -name "*.opus" -o -name "*.m4a" -o -name "*.mp3" -o -name "*.webm" \) | head -1) || :
      [ -f "$track_media" ] && track_ext="${track_media##*.}" || track_ext="opus"
    } || :

    # --- set epoch mtime on thumbnails and video (original files)
    find "$dx/" -maxdepth 1 -name "*${track_id}*" \
      \( -name "*.webp" -o -name "*.jpg" -o -name "*.png" \) \
      -exec touch -t "$epoch_touchtime" {} \; 2>/dev/null || :
    [ "$do_video" ] && { find "$dx/" -maxdepth 1 -name "*${track_id}*" \
      \( -name "*.mp4" -o -name "*.mkv" -o -name "*.mov" -o -name "*.webm" \) \
      -exec touch -t "$epoch_touchtime" {} \; 2>/dev/null || : ;} || :

    # --- audio media: epoch mtime and @ hardlink (audio plan only)
    media_master="$d/@/_^${track_id}.${track_ext}" # prospective when no audio pass
    [ "$do_audio" ] && {
      read -d '' track_media < <(find "$dx/" -mindepth 1 -maxdepth 1 \
        -name "*${track_id}.${track_ext}") || :
      [ -f "$track_media" ] || { chkwrn "$FUNCNAME : media not found '*${track_id}.${track_ext}' (695f501b)" ; continue ;}
      touch -t "$epoch_touchtime" "$track_media"
      ln -f "$track_media" "$media_master"
    } || :

    # --- staging txt: playlist -> folio (sans 00 prefix); single -> $d (with 00
    #     prefix, pending); never overwritten, xs indexed on collision
    [ "$opt_playlist" ] && {
      [ -f "$dx/${jf##*/}.txt" ] && {
        $verb "staging txt exists, skipping: $dx/${jf##*/}.txt"
      } || {
        _yt_json_txt "$jf" "$media_master" "$dx" "$ts_touchtime" "$ts_header" \
          && mv "$_yt_json_txt_out" "$dx/${jf##*/}.txt"
      }
    } || {
      [ -f "$d/00${jf##*/}.txt" ] && {
        $verb "staging txt exists, skipping: $d/00${jf##*/}.txt"
      } || {
        _yt_json_txt "$jf" "$media_master" "$d" "$ts_touchtime" "$ts_header"
      }
    }

    # --- comment yaml (unless --nyc)
    [ "$opt_nyc" ] || {
      local com_opts=
      [ "$opt_utf8" ] && com_opts="$com_opts -u"
      [ "$opt_no_expand" ] && com_opts="$com_opts -x"
      _yt_com_json_yml $com_opts "$jf" "$ts_touchtime" || $verb "comment extraction skipped for $track_id"
    }

    # --- subtitles: srt original to epoch mtime, transcript (meta header,
    #     inline chapters from json) written to its final path with ts mtime;
    #     placement follows staging: playlist -> folio sans 00; single -> $d
    #     pending with 00; existing transcripts are never overwritten
    [ "$do_subs" ] && {
      local track_srts=() srt_txt=
      readarray -t track_srts < <(find "$dx/" -maxdepth 1 -name "*${track_id}*.srt" 2>/dev/null)
      for srt_file in "${track_srts[@]}" ; do
        touch -t "$epoch_touchtime" "$srt_file"
        [ "$opt_playlist" ] \
          && srt_txt="$dx/${srt_file##*/}.txt" \
          || srt_txt="$d/00${srt_file##*/}.txt"
        [ -f "$srt_txt" ] && { $verb "srt transcript exists, skipping: $srt_txt" ; continue ;} || :
        _yt_srt_txt "$srt_file" "$jf" "$srt_txt" && touch -t "$ts_touchtime" "$srt_txt" \
          || chkwrn "$FUNCNAME : srt_txt failed '$srt_file' (6a777d18)"
      done
    } || :

  done

  # --- playlist aggregate: strip metadata, concatenate to .list.txt (pending, $d)
  #     name carries the foli xs for traceability; collisions index the xs
  [ "$opt_playlist" ] && {
    local staged=() list_file= sfx=0
    readarray -t staged < <(find "$dx/" -maxdepth 1 -name "*info.json.txt" | sort)
    [ ${#staged[@]} -gt 0 ] && {
      list_file="$d/00${xs}${sfx},${safe_title}-^${playlist_id}.list.txt"
      [ -e "$list_file" ] && { sfx=2
        while [ -e "$d/00${xs}${sfx},${safe_title}-^${playlist_id}.list.txt" ] ; do sfx=$((sfx+1)) ; done
        list_file="$d/00${xs}${sfx},${safe_title}-^${playlist_id}.list.txt" ;} || :
      awk '/^--- metadata/{nextfile}; {print}' "${staged[@]}" >"$list_file"
      touch -t "$ts_touchtime" "$list_file"
      chktrue "$list_file"
    } || chkwrn "$FUNCNAME : no staging txt for aggregate (6a777d19)"
  } || :

  } # _yt 695f5000


_yt_help () { # display _yt usage
cat <<'EOF'
_yt --- yt-dlp wrapper for media download and organization

SYNOPSIS
  _yt [-ptvVjuxh] [--to|--vo|--jo] [--ta] [--video[=RES]] [--nc] [--nyc] [--] URL|ID [DIR]

DESCRIPTION
  Every option composes one execution plan. The default plan downloads
  audio, always captures info.json, and creates staging txt bookmarks.
  -t -v add features to the default; --to --vo --jo suppress the audio
  default and run only the named feature (combinable). Staging
  *.info.json.txt location encodes downstream status: target dir is
  pending, beside its info.json data is complete; staging is never
  overwritten---name collisions index the xs ({xs}2, {xs}3, ...).

ARGUMENTS
  URL|ID    YouTube URL or video ID (tracking parameters stripped)
            ids with a leading dash follow --
  DIR       Target directory (default: ./)

OPTIONS
  -p        Treat input as playlist (shared folio, padded index prefix)
              Single metadata fetch reused for markers and reports
              Duplicate check against $_yt_root for marker file
              If existing playlist found, prompt: (a)bort/(c)ontinue new foli/(r)esume
              Retry: download missing tracks into existing foli (reuses xs)
  -t        Add SRT subtitles (upstream srt preferred, converted
              otherwise), aggressive english variant selection, converted
              to transcript txt with meta header and inline chapter
              markers; transcript follows the staging convention
              (playlist: folio sans 00; single: DIR with 00 prefix)
  --ta      Auto-translated english subtitles, implies -t
  -v        Add video, first available from default set (1080/720/480/360)
  -V        Add video, highest resolution
  --video[=RES]  Add video at RES; RES 0 lists formats and prompts;
              without RES the default set applies
  -j        Default alias (info.json is always captured)
  --to      Only subtitles + transcripts + staging (no audio)
  --vo      Only video + staging (no audio)
  --jo      Only metadata fetch + staging (no media)
  --nc      Skip comments in JSON download
  --nyc     Skip comment post-processing to YAML
  -u        Pass to _yt_com_json_yml: retain UTF-8 encoding
  -x        Pass to _yt_com_json_yml: raw comment text (no escape expansion)
  -h, --help    Display this help

OUTPUT STRUCTURE
  ./foli/{xs_maj}/{xs_min}/   folio with media, json, subs, thumbnails, com.yml
  ./@/_^{id}.{ext}            audio hardlink for programmatic access
  ./00{xs},{tmpl}.info.json.txt   f2rb2mp3 staging data (single track, pending)
  ./00{xs},{tmpl}.{lang}.srt.txt   single-track transcript beside staging
  Playlist:
    {foli}/{xs},{playlist_title}-^{playlist_id}.meta.json   playlist metadata marker
    {foli}/{xs}{n},{tmpl}.info.json.txt              per-track staging (in folio)
    {foli}/{xs}{n},{tmpl}.{lang}.srt.txt             per-track transcript (in folio)
    ./00{xs}0,{playlist_title}-^{playlist_id}.list.txt   aggregated staging (pending)
    {foli}/{xs},{playlist_title}-^{playlist_id}.unavail.yml   unavailable tracks
      (per-track staging minus metadata sections, concatenated)
    Retry: reuses existing foli and xs; list.txt collisions index the xs

TIMESTAMPS
  Original files (media, srt subs, thumbnails): epoch mtime from json
  Derived files (json, txt, yml): ts function mtime (download time)

DOWNLOAD RETRY
  Failed ytdl invocations report, clean partial downloads (never
  pre-existing data), and retry: $_yt_tries attempts total (default 3)
  after $_yt_delay seconds (default 15)

ENVIRONMENT
  ytdl       Path to yt-dlp binary (default: yt-dlp)
  _yt_root   Duplicate detection root, media and playlist markers (default: DIR/..)
  _yt_tries  Total download attempts (default: 3)
  _yt_delay  Delay between attempts, seconds (default: 15)

HELPER FUNCTIONS
  _yt_json_txt JSON MEDIA DIR [TOUCHTIME] [TS_HEADER]   Extract metadata to staging txt
  _yt_srt_txt SRT [JSON] [OUT]              Convert SRT to transcript (meta header, chapters)
  _yt_vtt_txt VTT [JSON] [OUT]              Convert VTT to transcript (manual use)
  _yt_com_json_yml [-ux] JSON [TOUCHTIME]   Extract comments to YAML

EXAMPLES
  _yt dQw4w9WgXcQ                 Download audio + metadata
  _yt -tv dQw4w9WgXcQ ./music     Add transcripts + video (default set)
  _yt --video=0 dQw4w9WgXcQ       Add video, interactive resolution
  _yt -p PLxyz123 ./playlists     Download playlist (all tracks)
  _yt -p PLxyz123 ./playlists     Retry: re-run same command, select (r)
  _yt --jo dQw4w9WgXcQ ./meta     Metadata-only fetch
  _yt --to dQw4w9WgXcQ ./subs     Subtitles + transcripts + staging only
EOF
}


# =============================================================================
# _yt_json_txt --- extract info.json to txt for f2rb2mp3 staging
# =============================================================================

_yt_json_txt () { # create f2rb2mp3 staging data from youtube info.json
  # rev 6a777dfb 20260808; final path exported in _yt_json_txt_out (not local)
  local json_file="$1" media_master="$2" txt_dir="${3:-.}" touchtime="${4:-}" ts_header="${5:-}"
  local verb="${verb:-devnul}"
  local json= xs= id= file_ext= duration= title= fulltitle=
  local chapters= description= author_comments= metadata=

  # --- help dispatch
  [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] && { _yt_json_txt_help ; return 0 ;}

  # --- input validation
  [ "$json_file" ] || { chkerr "usage: $FUNCNAME"' "$json" "$media_master" "$txt_dir" [touchtime] [ts_header] (695f5101)' ; return 1 ;}
  [ "$media_master" ] || { chkerr "usage: $FUNCNAME"' "$json" "$media_master" "$txt_dir" [touchtime] [ts_header] (695f5102)' ; return 1 ;}
  [ -f "$json_file" ] || { chkerr "$FUNCNAME : json_file not found '$json_file' (695f5103)" ; return 1 ;}
  xs="${json_file##*/}"; xs="${xs%%,*}" # extract xs from filename

  # --- output path: never overwrite, index xs on collision ({xs}2, {xs}3, ...)
  local out_name="00${json_file##*/}.txt" out_head= out_tail= i=
  [ -e "${txt_dir}/${out_name}" ] && {
    out_head="${json_file##*/}" ; out_tail="${out_head#*,}" ; out_head="${out_head%%,*}"
    i=2 ; while [ -e "${txt_dir}/00${out_head}${i},${out_tail}.txt" ] ; do i=$((i+1)) ; done
    out_name="00${out_head}${i},${out_tail}.txt" ;} || :
  _yt_json_txt_out="${txt_dir}/${out_name}"

  # --- ts_header: use provided or reconstruct from xs
  [ -z "$ts_header" ] && {
    local xs_dec=$(printf '%d' "0x${xs}" 2>/dev/null) || xs_dec=0
    ts_header="$xs $(_yt_date "$xs_dec" +"%Y%m%d %H%M%S %Z %a %I:%M %p %e %b %Y" 2>/dev/null || echo "$xs")"
  }

  # --- parse json (defensive - missing fields yield empty, jq/yq errors visible on stderr)
  read -rd '' json <"$json_file" || true ; $verb "json from $json_file"
  [ -z "$json" ] && { chkwrn "$FUNCNAME : empty json file '$json_file' (695f5105)" ; return 1 ;}
  read -r id file_ext duration < <(jq -r '[.id // "", .ext // "", .duration_string // ""] | @tsv' <<<"$json") || true
  read -rd '' title < <(jq -r '.title // ""' <<<"$json") || true
  [ -z "$title" ] && chkwrn "$FUNCNAME : empty title (695f5106)" ; $verb title
  read -rd '' fulltitle < <(jq -r '.fulltitle // ""' <<<"$json") || true
  [ -z "$fulltitle" ] && chkwrn "$FUNCNAME : empty fulltitle (695f5107)" ; $verb fulltitle
  read -rd '' chapters < <(yq -ry -w10000 '(.chapters // [])[] | {ss: .start_time, to: .end_time, ooo: .title}' <<<"$json") || true
  [ -z "$chapters" ] && chkwrn "$FUNCNAME : no chapters (695f5108)" ; $verb chapters
  read -rd '' description < <(yq -r '.description // ""' <<<"$json") || true
  [ -z "$description" ] && chkwrn "$FUNCNAME : empty description (695f5109)" ; $verb description
  read -rd '' author_comments < <(yq -r '(.comments // []) | sort_by(.timestamp) | .[] | select(.author_is_uploader == true) | .text' <<<"$json") || true
  $verb author_comments
  read -rd '' metadata < <(yq -ry \
    'del(.formats, .thumbnail, .thumbnails, .downloader_options,
    .http_headers, .webpage_url_basename, .author_thumbnail,
    .playable_in_embed, .live_status, .extractor, .is_live, .was_live,
    .heatmap, ._format_sort_fields, .automatic_captions)' <<<"$json") || true
  [ -z "$metadata" ] && chkwrn "$FUNCNAME : empty metadata (695f510a)" ; $verb metadata

  # --- generate output (ascii//TRANSLIT boundary through author_comments)
  { echo "# $ts_header"
    echo "# see $FUNCNAME (695f5100), applied iconv -f utf-8 -c -t ascii//TRANSLIT"
    echo "# $json_file"
    printf "# ${out_name}\n\n"
    printf "ss= ; export verb=chkwrn ss= to= t= p= f= c=r3 F= CF= off= tp= lra= i= cmp=pard v=3db\n"
    printf "ss= ; export _f=./@/%s\n\n" "${media_master##*/}"
    printf "ss= _a=%s\n" "$title"
    printf "ss= _r=%s\n\n" "$fulltitle"
    printf ' ss= to= f2rb2mp3 $_f ooo,${_a}-Trak_Title-${_r}\n%s\n\n' "$duration"
    printf -- "--- chapters "
    printf -- "\n%s\n\n" "$chapters" \
      | sed -e 's/: /=/' -e 's/\.0$//' -e "s/'//g" -e 's/ /_/g' -e '/^---$/d' \
            -e 's/^ooo=/f2rb2mp3 $_f ooo,${_a}-/' -e '/^f2rb/s/$/-${_r}/' -e 's/\&/and/g' \
      | tr -d '()[].;:`"' \
      | awk -v xs="$xs" '{ gsub(/ ooo,/, sprintf(" p%s%03x,", xs, NR)); print }'
    printf -- "--- title \n%s\n\n" "$title"
    printf -- "--- description \n%s\n\n" "$description"
    printf -- "--- author_comments \n%s\n\n" "$author_comments" | tr -s '\n\r' '\n' ; echo
    echo "# end of ascii//TRANSLIT"
    } | iconv -f utf-8 -c -t ascii//TRANSLIT >"${_yt_json_txt_out}~" || true

  # --- append metadata (utf-8 preserved)
  printf -- "--- metadata \n%s\n\n" "$metadata" >>"${_yt_json_txt_out}~" \
    && mv "${_yt_json_txt_out}~" "$_yt_json_txt_out" \
    || { chkerr "$FUNCNAME : error creating '$_yt_json_txt_out' (695f510b)" ; return 1 ;}

  # --- set timestamp if provided
  [ "$touchtime" ] && touch -t "$touchtime" "$_yt_json_txt_out"
  chktrue "$_yt_json_txt_out"
  } # _yt_json_txt 695f5100


_yt_json_txt_help () { # display _yt_json_txt usage
cat <<'EOF'
_yt_json_txt --- extract YouTube metadata JSON to f2rb2mp3 staging txt

SYNOPSIS
  _yt_json_txt JSON_FILE MEDIA_MASTER [TXT_DIR] [TOUCHTIME] [TS_HEADER]

DESCRIPTION
  Parse YouTube info.json, extract critical metadata, create staging
  data file for f2rb2mp3 audio processing workflow. Existing staging
  files are never overwritten; on name collision the xs is indexed
  ({xs}2, {xs}3, ...). Final path exported in $_yt_json_txt_out.

ARGUMENTS
  JSON_FILE     Path to {template}.info.json
  MEDIA_MASTER  Path to media file (for _f variable, prospective allowed)
  TXT_DIR       Output directory (default: ./)
  TOUCHTIME     Optional timestamp in CCYYMMDDhhmm.SS format
  TS_HEADER     Optional full ts output for file header (reconstructed from xs if omitted)

OUTPUT
  {TXT_DIR}/00{json_filename}.txt (xs indexed on collision)
EOF
}


# =============================================================================
# _yt_sub_txt --- subtitle to transcript core (vtt and srt)
# =============================================================================

_yt_sub_txt () { # create transcript txt from subtitle file, optional json meta
  # rev 6a777dfb; header and inline chapter markers sourced from info.json
  local sub_file="${1:-}" json_file="${2:-}" txt_file="${3:-}" chap= hdr_epoch=

  # --- input validation
  [ "$sub_file" ] || { chkerr "usage: $FUNCNAME SUB_FILE [JSON_FILE] [OUT_FILE] (6a777d34)" ; return 1 ;}
  [ -f "$sub_file" ] || { chkerr "$FUNCNAME : file not found '$sub_file' (6a777d35)" ; return 1 ;}
  [ -z "$json_file" ] || [ -f "$json_file" ] || { chkerr "$FUNCNAME : json not found '$json_file' (6a777d36)" ; return 1 ;}
  txt_file="${txt_file:-${sub_file}.txt}" # default beside source

  { # --- meta header from json (timestamp, title, url, channel, date, duration)
    [ "$json_file" ] && {
      read -r hdr_epoch < <(jq -r '.timestamp // empty' "$json_file") || :
      [ "$hdr_epoch" ] \
        && echo "# $hdr_epoch $(_yt_date "$hdr_epoch" +"%Y%m%d %H%M%S %Z %a %I:%M %p %e %b %Y" 2>/dev/null)" \
        || :
      jq -r '"# \(.title // "")",
             "# \(.webpage_url // "")",
             "# \(.channel // .uploader // "") \(.upload_date // "") \(.duration_string // "")"' "$json_file"
      echo "--- description"
      jq -r '.description // ""' "$json_file"
      echo "--- transcript"
    } || :
    # --- chapter stream "seconds<tab>title" for inline markers
    [ "$json_file" ] && { read -rd '' chap < <(jq -r \
      '(.chapters // [])[] | "\(.start_time)\t\(.title)"' "$json_file") || : ;} || :
    # --- body: chapters interleaved at cue time (seconds and HH:MM:SS),
    #     cue numbers, timing, header lines, and tags stripped, dedupe
    awk -F'\t' '
      NR==FNR { if ($0 != "") { nc++ ; cs[nc]=$1+0 ; ct[nc]=$2 } ; next }
      /-->/ { t=$0 ; sub(/ *-->.*/,"",t) ; gsub(/,/,".",t)
        nf=split(t,f,":")
        if (nf==3) sec=f[1]*3600+f[2]*60+f[3]+0 ; else sec=f[1]*60+f[2]+0
        while (ci<nc) {
          if (sec>=cs[ci+1]) { ci++
            h=int(cs[ci]/3600) ; m=int((cs[ci]%3600)/60) ; s=int(cs[ci]%60)
            printf "--- %ds %02d:%02d:%02d %s\n", cs[ci], h, m, s, ct[ci] }
          else break }
        next }
      /^WEBVTT/ || /^Kind:/ || /^Language:/ || /^NOTE/ || /^STYLE/ { next }
      /^[0-9]+[[:space:]]*$/ { next }
      /^[[:space:]]*$/ { next }
      { line=$0 ; gsub(/<[^>]*>/,"",line) ; gsub(/&nbsp;/," ",line) ; print line }
    ' <(printf '%s\n' "$chap") "$sub_file" | uniq
  } >"$txt_file" \
    || { chkerr "$FUNCNAME : could not create '$txt_file' (6a777d37)" ; return 1 ;}
  chktrue "$txt_file"
  } # _yt_sub_txt 6a777d34


# =============================================================================
# _yt_vtt_txt --- convert VTT subtitles to plain transcript
# =============================================================================

_yt_vtt_txt () { # create transcript from vtt subtitles
  # --- help dispatch
  [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] && { _yt_vtt_txt_help ; return 0 ;}
  _yt_sub_txt "$@"
  } # _yt_vtt_txt 695f5200


_yt_vtt_txt_help () { # display _yt_vtt_txt usage
cat <<'EOF'
_yt_vtt_txt --- convert VTT subtitles to plain text transcript

SYNOPSIS
  _yt_vtt_txt VTT_FILE [JSON_FILE] [OUT_FILE]

DESCRIPTION
  Strip WebVTT header, timing metadata, HTML tags, deduplicate lines.
  With JSON_FILE, prepend meta header (timestamp, title, url, channel,
  date, duration, description) and interleave chapter markers at cue
  time as "--- {sec}s HH:MM:SS {title}".

OUTPUT
  OUT_FILE, or {VTT_FILE}.txt alongside source
EOF
}


# =============================================================================
# _yt_srt_txt --- convert SRT subtitles to plain transcript
# =============================================================================

_yt_srt_txt () { # create transcript from srt subtitles
  # --- help dispatch
  [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] && { _yt_srt_txt_help ; return 0 ;}
  _yt_sub_txt "$@"
  } # _yt_srt_txt 695f5300


_yt_srt_txt_help () { # display _yt_srt_txt usage
cat <<'EOF'
_yt_srt_txt --- convert SRT subtitles to plain text transcript

SYNOPSIS
  _yt_srt_txt SRT_FILE [JSON_FILE] [OUT_FILE]

DESCRIPTION
  Strip cue numbers, timing metadata, HTML tags, deduplicate lines.
  With JSON_FILE, prepend meta header (timestamp, title, url, channel,
  date, duration, description) and interleave chapter markers at cue
  time as "--- {sec}s HH:MM:SS {title}".

OUTPUT
  OUT_FILE, or {SRT_FILE}.txt alongside source
EOF
}


# =============================================================================
# _yt_com_json_yml --- extract comments from JSON to YAML
# =============================================================================

_yt_com_json_yml () { # extract youtube comments to structured yaml
  local json_file= touchtime= opt_utf8= opt_no_expand= out_file= json_dir=
  local id= title= description= upload_date= duration= comment_count=
  local OPTIND=1 OPTARG= opt=

  # --- help dispatch
  [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] && { _yt_com_json_yml_help ; return 0 ;}

  # --- option parsing
  while getopts "uxh" opt ; do
    case "$opt" in
      u) opt_utf8=1 ;;
      x) opt_no_expand=1 ;;
      h) _yt_com_json_yml_help ; return 0 ;;
      *) chkerr "$FUNCNAME : unknown option (695f5401)" ; return 1 ;;
    esac
  done
  shift $((OPTIND - 1))
  json_file="${1:-}"
  touchtime="${2:-}"

  # --- input validation
  [ "$json_file" ] || { chkerr "usage: $FUNCNAME [-ux] JSON_FILE [TOUCHTIME] (695f5403)" ; return 1 ;}
  [ -f "$json_file" ] || { chkerr "$FUNCNAME : file not found '$json_file' (695f5404)" ; return 1 ;}
  json_dir="${json_file%/*}"
  out_file="${json_file%.info.json}.com.yml"

  # --- extract meta fields (jq errors visible on stderr, defaults on empty)
  read -r id < <(jq -r '.id // ""' "$json_file") || true
  read -r title < <(jq -r '.title // ""' "$json_file") || true
  read -r upload_date < <(jq -r '.upload_date // ""' "$json_file") || true
  read -r duration < <(jq -r '.duration_string // ""' "$json_file") || true
  read -r comment_count < <(jq -r '.comment_count // 0' "$json_file") || comment_count=0

  # --- extract and format comments via jq/yq pipeline
  # sort by parent timestamp (nulls first = root), then comment timestamp
  # format: meta line + literal text block
  # note: jq -r expands JSON escapes (\n -> newline); -x emits @json raw form
  {
    # --- yaml header
    cat <<META
meta:
  id: $id
  title: '$(printf '%s' "$title" | sed "s/'/''/g")'
  upload_date: $upload_date
  duration: $duration
  comment_count: $comment_count
META

    # --- author comments section (empty array yields no output, section header only)
    echo "author_comments:"
    jq -r --arg cc "$comment_count" --arg raw "${opt_no_expand:+1}" '
      (.comments // []) | map(select(.author_is_uploader == true))
      | sort_by(.timestamp // 0)
      | .[] |
      "  - meta: \(.timestamp // 0) \(.like_count // 0)/\($cc)" +
      (if .is_favorited then " [favored|1]" else "" end) +
      (if .is_pinned then " [pin|1]" else "" end) +
      " \(.id // "") \(.parent // "root") \(.author_url // "")\n" +
      "    text: |\n" +
      ((.text // "") | (if $raw == "1" then @json else . end)
        | split("\n") | map("      " + .) | join("\n"))
    ' "$json_file" || true

    # --- all comments section (including author, sorted)
    echo "comments:"
    jq -r --arg cc "$comment_count" --arg raw "${opt_no_expand:+1}" '
      (.comments // [])
      | sort_by([(.parent // ""), (.timestamp // 0)])
      | .[] |
      "  - meta: \(.timestamp // 0) \(.like_count // 0)/\($cc)" +
      (if .is_favorited then " [favored|1]" else "" end) +
      (if .is_pinned then " [pin|1]" else "" end) +
      " \(.id // "") \(.parent // "root") \(.author_url // "")\n" +
      "    text: |\n" +
      ((.text // "") | (if $raw == "1" then @json else . end)
        | split("\n") | map("      " + .) | join("\n"))
    ' "$json_file" || true

  } | {
    # --- conditional encoding conversion (iconv may warn on transliteration, absorb exit)
    if [ "$opt_utf8" ] ; then cat ; else iconv -f utf-8 -c -t ascii//TRANSLIT || true ; fi
  } >"$out_file"

  # --- set timestamp if provided
  [ "$touchtime" ] && touch -t "$touchtime" "$out_file"
  [ -s "$out_file" ] && chktrue "$out_file" || chkwrn "$FUNCNAME : empty output '$out_file' (695f5405)"
  } # _yt_com_json_yml 695f5400


_yt_com_json_yml_help () { # display _yt_com_json_yml usage
cat <<'EOF'
_yt_com_json_yml --- extract YouTube comments to structured YAML

SYNOPSIS
  _yt_com_json_yml [-ux] JSON_FILE [TOUCHTIME]

DESCRIPTION
  Extract comments from info.json to YAML with metadata header,
  author comments first, then all comments sorted by thread.
  Default expands JSON escapes to presentation form.

OPTIONS
  -u    Retain UTF-8 encoding (disable ascii//TRANSLIT)
  -x    Raw comment text (@json form, no escape expansion)

ARGUMENTS
  JSON_FILE   Path to {template}.info.json
  TOUCHTIME   Optional timestamp in CCYYMMDDhhmm.SS format

OUTPUT
  {json_dir}/{template}.com.yml beside input file

FORMAT
  meta: {id, title, upload_date, duration, comment_count}
  author_comments: [{meta, text}...]
  comments: [{meta, text}...] sorted by parent/timestamp
EOF
}


# =============================================================================
# Source guard --- allow sourcing without execution
# =============================================================================

[ "${BASH_SOURCE[0]}" = "$0" ] && {
  case "${1:-}" in
    -h|--help) _yt_help ;;
    _yt_json_txt) shift ; _yt_json_txt "$@" ;;
    _yt_vtt_txt) shift ; _yt_vtt_txt "$@" ;;
    _yt_srt_txt) shift ; _yt_srt_txt "$@" ;;
    _yt_com_json_yml) shift ; _yt_com_json_yml "$@" ;;
    *) _yt "$@" ;;
  esac
} || true
