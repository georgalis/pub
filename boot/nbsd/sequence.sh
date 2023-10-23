#!/bin/sh

# (C) 2023 George Georgalis <george@galis.org> unlimited use with this notice
# 6536a4f43 foundation code based Claud 2 prompt to enhance rcorder functionality

# given a bootstrap setup directory (arg1) with scripts annoted in
# rcorder format, consider respective PROVIDE, REQUIRE, and BEFORE
# metadata, and additional args denoting PROVIDE requirements from
# the setup directory scripts, the required scripts in the proper
# sequence, to satisfy the dependencies, are discovered and printed.
#
# Through the following key steps:
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
# detecting cycles and errors.
#
# The key data structures are the 'required', 'provided', 'before'
# and 'tsorted' arrays. By tracking them separately, we can build
# the dependency graph and sort it for the correct output.


rcd="$1"
[ "$#" -gt 1 ] && shift
provide=$@

devnul() { return 0 ;}                                                 #:> drop args
stderr() {  [ "$*" ] && echo "$*" 1>&2 || true ;}                      #:> args to stderr, or noop if null
chkwrn() {  [ "$*" ] && { stderr    "^^^ $*" ; return $? ;} || true ;} #:> wrn stderr args return 0, noop if null
chkerr() {  [ "$*" ] && { stderr    ">>> $*" ; return 1  ;} || true ;} #:> err stderr args return 1, noop if null

[ "$rcd" ] || { chkerr "$0 : no rc.d (arg1) provided (6536a66a)" ; exit 1 ;}
[ -d "$rcd" ] || { chkerr "$0 : rc.d (arg1) not a directory (6536a6a4)" ; exit 1 ;}
cd "$rcd"
[ "$provide" ] || provide='.'

required=()
provided=()
before=()

# set verb to chkwrn for debug output
verb=devnul
verb=chkwrn

# Parse PROVIDED data
for p in $provide; do
  provided+=("$p")
  done
# verb
for i in ${!provided[@]}; do
  $verb "provided[$i] = ${provided[$i]}"
  done

# Find scripts that PROVIDE services
for p in "${provided[@]}"; do
  found=0
  for f in *; do
    [ -d "$f" ] || if grep -Eq "^# PROVIDE:.*( ${p} | ${p}$)" "$f"; then
      required+=("$f")
      found+=1
      break
    fi
  done
  [ $found -eq 0 ] && { chkerr "$0 : No script provides $p (6536c080)" ; exit 1 ;}
  [ $found -gt 1 ] && { chkerr "$0 : Multiple scripts provide $p (6536c0c8)" ; exit 1 ;}
done
# verb
for i in ${!required[@]}; do
  $verb "required[$i] = ${required[$i]}"
  done

$verb "required: ${required[@]}"
# Build BEFORE dependency graph
for r in "${required[@]}"; do
  deps=$(grep -E '^# BEFORE: ' "$r" | cut -d: -f2-)
  for d in $deps; do
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


revargs () {
    local a out
    out="$1" ; shift || true
    while test $# -gt 0 ; do out="$1 $out" ; shift || true ; done
    echo "$out"
    }

# # Print sorted scripts + REQUIRE deps
# for ((i=${#tsorted[@]}-1; i>=0; i--)); do
#   s=${tsorted[$i]}
#   echo "$s"
#   deps=$(grep '^# REQUIRE: ' "$s" | cut -d: -f2-)
#   for d in $deps; do
#   for d in $deps; do
# 


for s in "${tsorted[@]}"; do
  echo "$s"
  deps=$(grep '^# REQUIRE: ' "$s" | cut -d: -f2-)
  for d in $deps; do
    if [ ${#required[@]} -eq 0 ]; then
      echo "Missing dependency: $d" >&2
      exit 1  
    fi
    echo "$d"
  done
done


$verb end
exit 0

