#!/bin/sh

# (C) 2023 George Georgalis <george@galis.org> unlimited use with this notice
# 6536a4f43 foundation code based on AI prompt to emulate rcorder in shell

# given a bootstrap setup directory (arg1) with scripts annotated in
# rcorder format, consider respective PROVIDE, REQUIRE, and BEFORE
# metadata, and additional args denoting PROVIDE requirements from
# the setup directory scripts. The required scripts in the proper
# sequence, to satisfy the dependencies, are discovered and printed,
# through the following key steps:
#
# 1. Parse the input PROVIDE requirement into an array.
#
# 2. Loop through each requirement and find scripts in the bootstrap
#      setup directory that PROVIDE it. Add those scripts to a
#      'required' array.
#    - If no script provides a service, exit with error.
#
# 3. Parse the BEFORE metadata for each required script and build
#      a 'before' array with before/after pairs.
#
# 4. Perform a topological sort on the required scripts using the
#      before dependency graph.
#    - Handle the case of no BEFORE dependencies by using original
#        required order.
#    - Loop through required array and check for back edges to
#        already visited nodes to detect cycles.
#    - Track visited nodes and append to tsorted array in dep order.
#
# 5. Print the sorted script list.
#    - For each script, print its REQUIRE dependencies.
#    - Check required array for missing dependencies, exit if found.
#
# This ensures we only print the minimum set of scripts needed
# for the provided services, in the proper dependency order while
# detecting loop cycles, and other errors.
#
# The key data structures are the 'required', 'provided', 'before'
# and 'tsorted' arrays. By tracking them separately, we can build
# the dependency graph and sort it for the correct output.

rcd="$1"
[ "$#" -gt 1 ] && shift
ask=$@

devnul() { return 0 ;}                                                 #:> drop args
stderr() {  [ "$*" ] && echo "$*" 1>&2 || true ;}                      #:> args to stderr, or noop if null
chkwrn() {  [ "$*" ] && { stderr    "^^^ $*" ; return $? ;} || true ;} #:> wrn stderr args return 0, noop if null
chkerr() {  [ "$*" ] && { stderr    ">>> $*" ; return 1  ;} || true ;} #:> err stderr args return 1, noop if null

[ "$rcd" ] || { chkerr "$0 : no rc.d (arg1) given (6536a66a)" ; exit 1 ;}
[ -d "$rcd" ] || { chkerr "$0 : rc.d (arg1) not a directory (6536a6a4)" ; exit 1 ;}
cd "$rcd"

# set verb to chkwrn for debug output
verb=chkwrn
verb=devnul

file_metadata() { awk ' /^# / { tag = $2
    if (tag == "PROVIDE:") { print; tag="REQUIRE:"
    } else if (tag == "REQUIRE:") { print; tag="BEFORE:"
    } else if (tag == "BEFORE:") { print; tag="KEYWORD:"
    } else if (tag == "KEYWORD:") { print; exit }
  } ' "$1" ;}

# Parse PROVIDED data
for p in $ask; do
  provided+=("$p")
  done
# verb
for i in ${!provided[@]}; do
  $verb "provided[$i] = ${provided[$i]}"
  done

# Find scripts that PROVIDE the ask
for p in "${provided[@]}"; do
  found=0
  for f in $(find . -maxdepth 1 -type f | sed 's=./=='); do
    file_metadata "$f" | grep -E "^# PROVIDE:.*( ${p} | ${p}$)" >/dev/null \
      && { required+=("$f") found+=1 ;}
  done
  [ $found -eq 0 ] && { chkerr "$0 : No script provides $p (6536c080)" ; exit 1 ;}
  [ $found -gt 1 ] && { chkerr "$0 : Multiple scripts provide $p (6536c0c8)" ; exit 1 ;}
done
# verb
for i in ${!required[@]}; do
  $verb "required[$i] = ${required[$i]}"
  done

# Validate REQUIRE dependencies
for r in "${required[@]}"; do
  for d in $(file_metadata "$r" | grep '^# REQUIRE: ' | cut -d: -f2-); do
    provided=0
    for f in $(find . -maxdepth 1 -type f | sed 's=./=='); do
      file_metadata "$f" | grep "^# PROVIDE: $d$" >/dev/null && { provided=1 ; break ;}
    done
    [ $provided -eq 0 ] && { chkerr "$0 : Missing dependency $d required by $r" ; exit 1 ;}
  done
done

$verb "required: ${required[@]}"
# Build BEFORE dependency graph
for r in "${required[@]}"; do
  for d in $(file_metadata "$r" | grep '^# BEFORE: ' | cut -d: -f2-); do
    $verb "before get $d"
    before+=("$r $d")
  done
done
# verb
for i in ${!before[@]}; do
  $verb "before[$i] = ${before[$i]}"
  done

$verb "Topological sort ${#required[@]}: ${required[@]}"
# Topological sort
tsorted=()
[ ${#before[@]} -eq 0 ] \
  && { # No BEFORE dependencies
    tsorted=("${required[@]}")
  } || { # With BEFORE dependencies
    visited=()
    for r in "${required[@]}"; do
      for b in "${before[@]}"; do
        read before after <<<"$b"
        [ "$after" = "$r" ] && [[ " ${visited[@]} " =~ " ${before} " ]] && \
          { chkerr "$0 : Dependency loop detected (6536c3b6)" ; exit 1 ;}
        done
      visited+=("$r")
      tsorted+=("$r")
      done
    required=("${tsorted[@]}")
  } # With BEFORE dependencies
$verb "sorted scripts ${tsorted[@]}"

# Print sorted scripts in reverse order
for ((i=${#tsorted[@]}-1; i>=0; i--)); do
 echo "${tsorted[$i]}"
 done

exit 0
