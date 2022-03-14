#!/usr/bin/env bash

cp $2/my_file.fnl /config/fnl/my_file.fnl
cp $2/my_macro.fnl /config/fnl/my_macro.fnl

/test/nvim.sh $1
time_first=$(stat -c %Y /root/.cache/nvim/hotpot/config/fnl/my_file.lua)

sleep 2
touch /config/fnl/my_file.fnl
/test/nvim.sh $1
time_touched=$(stat -c %Y /root/.cache/nvim/hotpot/config/fnl/my_file.lua)

cat <<EOF | assert "cache file is recompiled when source is touched"
  if [[ ! $time_first -lt $time_touched ]]; then
    fail "modified time was not incremented"
  fi
EOF

sleep 2
/test/nvim.sh $1
time_untouched=$(stat -c %Y /root/.cache/nvim/hotpot/config/fnl/my_file.lua)

cat <<EOF | assert "cache file is not modified if no changes occur"
  if [[ $time_touched -ne $time_untouched ]]; then
    fail "modified time was not equal"
  fi
EOF

sleep 2
touch /config/fnl/my_macro.fnl
/test/nvim.sh $1
time_dep_touched=$(stat -c %Y /root/.cache/nvim/hotpot/config/fnl/my_file.lua)

cat <<EOF | assert "cache file is recompiled after dependency is modified"
  if [[ ! $time_touched -lt $time_dep_touched ]]; then
    echo $time_a $time_b $time_c >> /run.log
    fail "modified time did not increment"
  fi
EOF
