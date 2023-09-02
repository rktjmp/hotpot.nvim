#!/usr/bin/env bash
set -eu

failed=0
tests=(require-a-fnl-file cache-invalidation dot-hotpot)

if [ $# -eq 1 ]; then
  tests=($1)
fi

for t in ${tests[@]};
do
  echo "Testing $t..."
  NVIM_APPNAME=$(uuidgen) nvim +"set columns=256" -l "new-tests/${t}.lua"
  if [ $? -ne 0 ]; then
    failed=1
  fi
done

exit $failed
