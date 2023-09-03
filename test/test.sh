#!/usr/bin/env bash
set -u

nvim_bin=${NVIM_BIN:-nvim}
failed_count=0
tests=(require-a-fnl-file cache-invalidation dot-hotpot api-make)
if [ $# -eq 1 ]; then
  tests=($1)
fi

for t in ${tests[@]};
do
  echo "SUITE START  $t..."
  NVIM_APPNAME=$(uuidgen) $nvim_bin +"set columns=256" -l "test/${t}.lua"
  if [ $? -ne 0 ]; then
    echo "SUITE FAILED $t"
    failed_count=1
  else
    echo "SUITE PASSED $t"
  fi
  echo ""
done

if [ $failed_count -ne 0 ]; then
  echo "SOME TESTS FAILED"
else
  echo "ALL TESTS PASSED"
fi
exit $failed_count
