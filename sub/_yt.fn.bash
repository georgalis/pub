#!/usr/bin/env bash
# rev 695f5300 20260107 --- yt-dlp wrapper suite for media download and organization
# synthesized from _yt_nvtt/_yt_json2txt canonical forms
#
# Directory Architecture:
#   $d/                                    root (default ./)
#   $d/00${xs},{template}.info.json.txt    f2rb2mp3 staging data
#   $d/@/_^{id}.{ext}                      hardlinked media (programmatic access)
#   $d/foli/{xs_maj}/{xs_min}/             folio per download timestamp
#     {xs},{template}.{ext}                original media + metadata + thumbnails
#     {xs},{template}.com.yml              comment yaml (unless --nyc)
#   Playlist: {xs}{playlist_index},{template}.{ext} in shared folio
#
# xs derivation: ts function (hex epoch), header via ts_header
# Timestamps: original files use epoch mtime, derived files use ts mtime
# Dependencies: $ytdl, $kdb (validated), ts, jq, yq, nbsed, iconv

# =============================================================================
# _yt --- primary entry for yt-dlp download and organization
# =============================================================================

_yt () { # ytdl wrapper: download media, organize folio, create staging txt
  local id= d= ytdl=${ytdl:-yt-dlp} verb=${verb:-devnul}
  local opt_playlist= opt_srt= opt_vtt= opt_video= opt_video_res=
  local opt_nc= opt_nyc= opt_json_only= opt_utf8= opt_no_expand=
  local opt_only_vtt= opt_only_srt=
  local xs= xs_date= xs_time= dx= existing= json_path= ext= media_file=
  local ts_touchtime= epoch= epoch_touchtime=
  local OPTIND=1 OPTARG= opt=

  # --- help dispatch
  [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] && { _yt_help ; return 0 ;}

  # --- pre-scan for long options before getopts
  local args=() arg=
  for arg in "$@" ; do
    case "$arg" in
      --video=*) opt_video=1 ; opt_video_res="bestvideo[height<=${arg#*=}]+bestaudio/best" ;;
      --nc) opt_nc=1 ;;
      --nyc) opt_nyc=1 ;;
      --ot) opt_only_vtt=1 ;;
      --os) opt_only_srt=1 ;;
      --help) _yt_help ; return 0 ;;
      --video) ;; # handled in second pass with its argument
      --*) ;; # ignore other long opts for now
      *) args+=("$arg") ;;
    esac
  done

  # --- getopts for short options (allows -tv, -vt, etc)
  set -- "${args[@]}"
  while getopts ":pstvVjuxh" opt ; do
    case "$opt" in
      p) opt_playlist=1 ;;
      s) opt_srt=1 ;;
      t) opt_vtt=1 ;;
      v) opt_video=1 ; opt_video_res="bestvideo[height<=720][fps<=60]+bestaudio/best" ;;
      V) opt_video=1 ; opt_video_res="bestvideo+bestaudio/best" ;;
      j) opt_json_only=1 ;;
      u) opt_utf8=1 ;;
      x) opt_no_expand=1 ;;
      h) _yt_help ; return 0 ;;
      :) chkerr "$FUNCNAME : option -$OPTARG requires argument (695f5001)" ; return 1 ;;
      \?) ;; # ignore unknown, may be positional starting with -
    esac
  done
  shift $((OPTIND - 1))

  # --- parse remaining args (handle --video VALUE and positionals)
  while [ $# -gt 0 ] ; do
    case "$1" in
      --video) opt_video=1 ; opt_video_res="bestvideo[height<=${2}]+bestaudio/best" ; shift 2 ;;
      -*) chkerr "$FUNCNAME : unknown option '$1' (695f5002)" ; return 1 ;;
      *) [ -z "$id" ] && { id="$1" ; shift ; continue ;}
         [ -z "$d" ] && { d="$1" ; shift ; continue ;}
         chkerr "$FUNCNAME : unexpected arg '$1' (695f5003)" ; return 1 ;;
    esac
  done

  # --- input validation
  [ "$id" ] || { chkerr "$FUNCNAME : no id? (695f5004)" ; return 1 ;}
  [[ "$id" =~ ^[A-Za-z0-9._/:?=\&-]+$ ]] || { chkerr "$FUNCNAME : unsafe id chars '$id' (695f5005)" ; return 1 ;}
  read id < <(sed -e 's/[?&]si=[[:alnum:]_-]\{16\}[&]*//' -e 's/\?$//' <<<"$id") # strip trackers
  d="${d:-.}"
  [ -d "$d" ] || mkdir -p "$d" || { chkerr "$FUNCNAME : invalid dir '$d' (695f5006)" ; return 1 ;}
  [ -d "$kdb" ] || { chkerr "$FUNCNAME : \$kdb not set to directory (695f5007)" ; return 1 ;}

  # --- timestamp via ts function
  # ts output: 695f4d58 20260107 222320 PST Wed 10:23 PM  7 Jan 2026
  local ts_out= ts_header=
  ts_out=$(ts) || { chkerr "$FUNCNAME : ts function failed (695f5008)" ; return 1 ;}
  read xs xs_date xs_time _ <<<"$ts_out"
  ts_header="$ts_out"
  # construct touchtime CCYYMMDDhhmm.SS from xs_date (CCYYMMDD) and xs_time (hhmmSS)
  ts_touchtime="${xs_date}${xs_time:0:4}.${xs_time:4:2}"

  # --- folio setup
  read dx < <(nbsed "s/\(....\)/\1\//;s:^:$d/foli/:" <<<"$xs") # eg ./foli/695f/4d58
  [ -d "$d/@" ] || mkdir -p "$d/@" || { chkerr "$FUNCNAME : cannot mkdir '$d/@' (695f5009)" ; return 1 ;}
  [ -d "$dx" ] && { chkerr "$FUNCNAME : race collision '$dx' (695f500a)" ; return 1 ;} || true
  mkdir -p "$dx" || { chkerr "$FUNCNAME : cannot mkdir '$dx' (695f500b)" ; return 1 ;}

  # --- pre-check: extract id and acodec, check for existing in $kdb
  read id ext < <($ytdl --no-playlist --no-warnings --ignore-config --no-check-formats --geo-bypass \
    --print id --print "%(acodec)s" -- "$id") \
    || { chkerr "$FUNCNAME : failed to load data '$id' (695f500c)" ; return 1 ;}
  read -d '' existing < <(sort -r < <(find -E "$kdb" -regex "$kdb/.*/(tmp|0)" -prune -false -o -name "*${id}*")) || true
  [ "$existing" ] && { echo "$existing"
    read -p "files found, continue (N/y) "
    [ "$REPLY" = "y" ] || return 1 ;} || true

  # --- only-vtt mode (download vtt + json, create txt)
  [ "$opt_only_vtt" ] && {
    $ytdl --write-info-json --no-warnings --restrict-filenames --skip-download --no-playlist \
      --write-sub --write-auto-sub --sub-langs "en,en-US,en-GB,en-AU" \
      -o "$dx/${xs},%(title)s-%(upload_date)s_^%(id)s.%(ext)s" -- "$id" 2>&1 \
      | { nbsed -l '/^\[youtube\] Sleeping/d;/Downloading video thumbnail/d' || true ;}
    read -d '' json_path < <(find "$dx/" -maxdepth 1 -name "*${id}.info.json") || true
    [ -e "$json_path" ] || { chkerr "$FUNCNAME : json not found (695f500d)" ; return 1 ;}
    # set ts mtime on json
    touch -t "$ts_touchtime" "$json_path"
    # process vtt files
    local vtt_files=() vtt_file=
    readarray -t vtt_files < <(find "$dx/" -maxdepth 1 -name "*${id}*.vtt" 2>/dev/null)
    [ ${#vtt_files[@]} -gt 0 ] || { chkwrn "$FUNCNAME : no vtt files found (695f500e)" ; return 0 ;}
    # set epoch mtime on vtt from json
    read epoch < <(jq -r '.timestamp // empty' "$json_path") || true
    [ "$epoch" ] && {
      epoch_touchtime=$(date -r "$epoch" +"%Y%m%d%H%M.%S")
      for vtt_file in "${vtt_files[@]}" ; do
        touch -t "$epoch_touchtime" "$vtt_file"
      done
    }
    # create transcripts
    for vtt_file in "${vtt_files[@]}" ; do
      _yt_vtt_txt "$vtt_file" && touch -t "$ts_touchtime" "${vtt_file}.txt"
    done
    return 0 ;}

  # --- only-srt mode (future implementation)
  [ "$opt_only_srt" ] && {
    chkwrn "$FUNCNAME : --os (only srt) not yet implemented (695f500f)"
    return 1 ;}

  # --- json-only mode
  [ "$opt_json_only" ] && {
    local json_opts="--write-info-json --no-warnings --restrict-filenames --skip-download --no-playlist"
    [ "$opt_nc" ] || json_opts="$json_opts --write-comments"
    [ "$opt_nc" ] || json_opts="$json_opts --extractor-args youtube:max_comments=all,all,all,all;comment_sort=newest"
    $ytdl $json_opts -o "$dx/${xs},%(title)s-%(upload_date)s_^%(id)s.%(ext)s" -- "$id" \
      || { chkerr "$FUNCNAME : json download failed (695f5010)" ; return 1 ;}
    read -d '' json_path < <(find "$dx/" -maxdepth 1 -name "*${id}.info.json") || true
    [ -e "$json_path" ] && { touch -t "$ts_touchtime" "$json_path" ; chktrue "$json_path" ;}
    return 0 ;}

  # --- build ytdl command options
  local ytdl_opts="--write-info-json --no-warnings --write-thumbnail --restrict-filenames"
  [ "$opt_nc" ] || ytdl_opts="$ytdl_opts --write-comments"
  [ "$opt_playlist" ] && ytdl_opts="$ytdl_opts --yes-playlist" || ytdl_opts="$ytdl_opts --no-playlist"
  [ "$opt_srt" ] && ytdl_opts="$ytdl_opts --write-sub --sub-langs en,en-US,en-GB,en-AU --sub-format srt"
  [ "$opt_vtt" ] && ytdl_opts="$ytdl_opts --write-sub --write-auto-sub --sub-langs en,en-US,en-GB,en-AU"

  # --- output template
  local tmpl=
  [ "$opt_playlist" ] \
    && tmpl="$dx/${xs}%(playlist_index)s,%(title)s-%(upload_date)s_^%(id)s.%(ext)s" \
    || tmpl="$dx/${xs},%(title)s-%(upload_date)s_^%(id)s.%(ext)s"

  # --- extractor args for full comment depth (unless --nc)
  local extractor_args=
  [ "$opt_nc" ] || extractor_args='--extractor-args youtube:max_comments=all,all,all,all;comment_sort=newest'

  # --- execute download: audio first (produces linkable file), then video if requested
  # note: nbsed exit isolated to prevent SIGPIPE from aborting ytdl
  $ytdl $ytdl_opts -f bestaudio --extract-audio --abort-on-error \
    $extractor_args \
    -o "$tmpl" -- "$id" 2>&1 \
    | { nbsed -l '/^\[youtube\] Sleeping/d;/API JSON reply thread/d;/replies API JSON page/d;/Downloading video thumbnail/d;/Video Thumbnail .* does not exist/d' || true ;}

  # --- video pass if requested (merged output, metadata already captured)
  [ "$opt_video" ] && {
    local ffmpeg_loc=
    read ffmpeg_loc < <(which ffmpeg8 2>/dev/null || which ffmpeg) || true
    $ytdl --restrict-filenames --no-warnings \
      ${ffmpeg_loc:+--ffmpeg-location "$ffmpeg_loc"} \
      -f "$opt_video_res" --abort-on-error --no-playlist \
      -o "$tmpl" -- "$id" 2>&1 \
      | { nbsed -l '/^\[youtube\] Sleeping/d;/Downloading video thumbnail/d' || true ;}
  } || true

  # --- locate json and media
  read -d '' json_path < <(find "$dx/" -maxdepth 1 -name "*${id}.info.json") || true
  [ -e "$json_path" ] || { chkerr "$FUNCNAME : json not found '$dx/*${id}.info.json' (695f5011)" ; return 1 ;}

  # --- extract epoch from json for original file timestamps
  read epoch < <(jq -r '.timestamp // empty' "$json_path") || true
  [ "$epoch" ] && epoch_touchtime=$(date -r "$epoch" +"%Y%m%d%H%M.%S") || epoch_touchtime="$ts_touchtime"

  # --- set timestamps: ts mtime on json (derived), epoch mtime on originals
  touch -t "$ts_touchtime" "$json_path"

  # --- determine audio extension from json (acodec for extracted audio file)
  read ext < <(jq -r '.acodec | @text' "$json_path") || { chkerr "$FUNCNAME : acodec key not found (695f5012)" ; return 1 ;}
  # fallback: check actual file if acodec yields unexpected value
  [ "$ext" = "none" ] || [ "$ext" = "null" ] && {
    read -d '' media_file < <(find "$dx/" -mindepth 1 -maxdepth 1 -name "*${id}.*" \
      \( -name "*.opus" -o -name "*.m4a" -o -name "*.mp3" -o -name "*.webm" \) | head -1) || true
    [ -f "$media_file" ] && ext="${media_file##*.}" || ext="opus"
  } || true

  # --- locate and link audio media
  read -d '' media_file < <(find "$dx/" -mindepth 1 -maxdepth 1 -name "*${id}.${ext}") || true
  [ -f "$media_file" ] || { chkerr "$FUNCNAME : media not found '$dx/*${id}.${ext}' (695f5013)" ; return 1 ;}

  # --- set epoch mtime on original media, thumbnails, vtt
  touch -t "$epoch_touchtime" "$media_file"
  find "$dx/" -maxdepth 1 \( -name "*.webp" -o -name "*.jpg" -o -name "*.png" -o -name "*.vtt" \) \
    -exec touch -t "$epoch_touchtime" {} \; 2>/dev/null || true

  # --- hardlink media
  ln -f "$media_file" "$d/@/_^${id}.${ext}"

  # --- generate staging txt (ts mtime applied inside function)
  _yt_json_txt "$json_path" "$d/@/_^${id}.${ext}" "$d" "$ts_touchtime" "$ts_header"

  # --- generate comment yaml (unless --nyc)
  [ "$opt_nyc" ] || {
    local com_opts=
    [ "$opt_utf8" ] && com_opts="$com_opts -u"
    [ "$opt_no_expand" ] && com_opts="$com_opts -x"
    _yt_com_json_yml $com_opts "$json_path" "$ts_touchtime" || $verb "comment extraction skipped"
  }

  # --- process vtt transcript if downloaded
  [ "$opt_vtt" ] && {
    local vtt_files=() vtt_file=
    readarray -t vtt_files < <(find "$dx/" -maxdepth 1 -name "*${id}*.vtt" 2>/dev/null)
    if [ ${#vtt_files[@]} -gt 0 ] ; then
      for vtt_file in "${vtt_files[@]}" ; do
        _yt_vtt_txt "$vtt_file" && touch -t "$ts_touchtime" "${vtt_file}.txt" || chkwrn "$FUNCNAME : vtt_txt failed '$vtt_file' (695f5014)"
      done
    else
      chkwrn "$FUNCNAME : no vtt files found for transcript (695f5015)"
    fi
  } || true

  } # _yt 695f5000


_yt_help () { # display _yt usage
cat <<'EOF'
_yt --- yt-dlp wrapper for media download and organization

SYNOPSIS
  _yt [-pstvVjuxh] [--video RES] [--nc] [--nyc] [--ot] [--os] URL|ID [DIR]

DESCRIPTION
  Download YouTube media with metadata, organize into folio structure,
  create programmatic access links and f2rb2mp3 staging files.

ARGUMENTS
  URL|ID    YouTube URL or video ID (tracking parameters stripped)
  DIR       Target directory (default: ./)

OPTIONS
  -p        Treat input as playlist (shared folio, padded index prefix)
  -s        Download SRT subtitles (English variants)
  -t        Download VTT subtitles (English variants), create transcript
  -v        Download 720p60 video
  -V        Download highest resolution video
  --video RES   Download specified video resolution
  --nc      Skip comments in JSON download
  --nyc     Skip comment post-processing to YAML
  --ot      Only download VTT subtitles + json, create transcript (no media)
  --os      Only download SRT subtitles + json (future, not implemented)
  -j        JSON-only download to DIR (no media)
  -u        Pass to _yt_com_json_yml: retain UTF-8 encoding
  -x        Pass to _yt_com_json_yml: disable escape expansion
  -h, --help    Display this help

OUTPUT STRUCTURE
  ./foli/{xs_maj}/{xs_min}/   folio with media, json, thumbnails, com.yml
  ./@/_^{id}.{ext}            hardlink for programmatic access
  ./00{xs},{tmpl}.info.json.txt   f2rb2mp3 staging data

TIMESTAMPS
  Original files (media, vtt, thumbnails): epoch mtime from json
  Derived files (json, txt, yml): ts function mtime (download time)

ENVIRONMENT
  ytdl      Path to yt-dlp binary (default: yt-dlp)
  kdb       Knowledge database directory for duplicate detection (required)

HELPER FUNCTIONS
  _yt_json_txt JSON MEDIA DIR [TOUCHTIME] [TS_HEADER]   Extract metadata to staging txt
  _yt_vtt_txt VTT                           Convert VTT to transcript
  _yt_com_json_yml [-ux] JSON [TOUCHTIME]   Extract comments to YAML

EXAMPLES
  _yt dQw4w9WgXcQ                 Download audio + metadata
  _yt -tv dQw4w9WgXcQ ./music     Download with VTT + 720p video
  _yt -p PLxyz123 ./playlists     Download playlist
  _yt -j dQw4w9WgXcQ ./meta       JSON-only download
  _yt --ot dQw4w9WgXcQ ./subs     VTT subtitles only + transcript
EOF
}


# =============================================================================
# _yt_json_txt --- extract info.json to txt for f2rb2mp3 staging
# =============================================================================

_yt_json_txt () { # create f2rb2mp3 staging data from youtube info.json
  # rev 695f5100 20260107
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
  [ -f "${txt_dir}/00${json_file##*/}.txt" ] && { chkerr "$FUNCNAME : exists '${txt_dir}/00${json_file##*/}.txt' (695f5104)" ; return 1 ;}

  # --- ts_header: use provided or reconstruct from xs
  [ -z "$ts_header" ] && {
    local xs_dec=$(printf '%d' "0x${xs}" 2>/dev/null) || xs_dec=0
    ts_header="$xs $(date -r "$xs_dec" +"%Y%m%d %H%M%S %Z %a %I:%M %p %e %b %Y" 2>/dev/null || echo "$xs")"
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
    printf "# ${json_file##*/}.txt\n\n"
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
    } | iconv -f utf-8 -c -t ascii//TRANSLIT >"${txt_dir}/${json_file##*/}.txt~" || true

  # --- append metadata (utf-8 preserved)
  printf -- "--- metadata \n%s\n\n" "$metadata" >>"${txt_dir}/${json_file##*/}.txt~" \
    && mv "${txt_dir}/${json_file##*/}.txt~" "${txt_dir}/00${json_file##*/}.txt" \
    || { chkerr "$FUNCNAME : error creating '${txt_dir}/00${json_file##*/}.txt' (695f510b)" ; return 1 ;}

  # --- set timestamp if provided
  [ "$touchtime" ] && touch -t "$touchtime" "${txt_dir}/00${json_file##*/}.txt"
  chktrue "${txt_dir}/00${json_file##*/}.txt"
  } # _yt_json_txt 695f5100


_yt_json_txt_help () { # display _yt_json_txt usage
cat <<'EOF'
_yt_json_txt --- extract YouTube metadata JSON to f2rb2mp3 staging txt

SYNOPSIS
  _yt_json_txt JSON_FILE MEDIA_MASTER [TXT_DIR] [TOUCHTIME] [TS_HEADER]

DESCRIPTION
  Parse YouTube info.json, extract critical metadata, create staging
  data file for f2rb2mp3 audio processing workflow.

ARGUMENTS
  JSON_FILE     Path to {template}.info.json
  MEDIA_MASTER  Path to media file (for _f variable)
  TXT_DIR       Output directory (default: ./)
  TOUCHTIME     Optional timestamp in CCYYMMDDhhmm.SS format
  TS_HEADER     Optional full ts output for file header (reconstructed from xs if omitted)

OUTPUT
  {TXT_DIR}/00{json_filename}.txt
EOF
}


# =============================================================================
# _yt_vtt_txt --- convert VTT subtitles to plain transcript
# =============================================================================

_yt_vtt_txt () { # create transcript from vtt subtitles
  local vtt_file="$1" txt_file=
  
  # --- help dispatch
  [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] && { _yt_vtt_txt_help ; return 0 ;}

  # --- input validation
  [ "$vtt_file" ] || { chkerr "usage: $FUNCNAME VTT_FILE (695f5201)" ; return 1 ;}
  [ -f "$vtt_file" ] || { chkerr "$FUNCNAME : file not found '$vtt_file' (695f5202)" ; return 1 ;}
  txt_file="${vtt_file}.txt"

  # --- transform: strip timing, tags, dedupe
  uniq < <(sed -e '/align:start position/d' \
               -e 's/<[^>]*>//g' \
               -e '/ --> /d' \
               -e '/^[[:space:]]*$/d' \
               -e 's/&nbsp;/ /g' "$vtt_file") >"$txt_file" \
    || { chkerr "$FUNCNAME : could not create '$txt_file' (695f5203)" ; return 1 ;}
  chktrue "$txt_file"
  } # _yt_vtt_txt 695f5200


_yt_vtt_txt_help () { # display _yt_vtt_txt usage
cat <<'EOF'
_yt_vtt_txt --- convert VTT subtitles to plain text transcript

SYNOPSIS
  _yt_vtt_txt VTT_FILE

DESCRIPTION
  Strip WebVTT timing metadata, HTML tags, deduplicate lines.

OUTPUT
  {VTT_FILE}.txt alongside source
EOF
}


# =============================================================================
# _yt_srt_txt --- convert SRT subtitles to plain transcript (deferred)
# =============================================================================

_yt_srt_txt () { # create transcript from srt subtitles (deferred)
  [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] && { _yt_srt_txt_help ; return 0 ;}
  chkwrn "$FUNCNAME : deferred implementation (695f5300)"
  return 1
  } # _yt_srt_txt 695f5300


_yt_srt_txt_help () { # display _yt_srt_txt usage
cat <<'EOF'
_yt_srt_txt --- convert SRT subtitles to plain text transcript

STATUS: Deferred implementation.
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

  # --- reserved flag warning
  [ "$opt_no_expand" ] && chkwrn "$FUNCNAME : -x flag reserved, escapes expanded via jq -r (695f5402)"

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
  # note: jq -r expands JSON escapes (\n -> newline) - -x flag reserved for future raw mode
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
    jq -r --arg cc "$comment_count" '
      (.comments // []) | map(select(.author_is_uploader == true))
      | sort_by(.timestamp // 0)
      | .[] | 
      "  - meta: \(.timestamp // 0) \(.like_count // 0)/\($cc)" +
      (if .is_favorited then " [favored|1]" else "" end) +
      (if .is_pinned then " [pin|1]" else "" end) +
      " \(.id // "") \(.parent // "root") \(.author_url // "")\n" +
      "    text: |\n" +
      ((.text // "") | split("\n") | map("      " + .) | join("\n"))
    ' "$json_file" || true

    # --- all comments section (including author, sorted)
    echo "comments:"
    jq -r --arg cc "$comment_count" '
      (.comments // [])
      | sort_by([(.parent // ""), (.timestamp // 0)])
      | .[] |
      "  - meta: \(.timestamp // 0) \(.like_count // 0)/\($cc)" +
      (if .is_favorited then " [favored|1]" else "" end) +
      (if .is_pinned then " [pin|1]" else "" end) +
      " \(.id // "") \(.parent // "root") \(.author_url // "")\n" +
      "    text: |\n" +
      ((.text // "") | split("\n") | map("      " + .) | join("\n"))
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

OPTIONS
  -u    Retain UTF-8 encoding (disable ascii//TRANSLIT)
  -x    Disable escape character expansion

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
