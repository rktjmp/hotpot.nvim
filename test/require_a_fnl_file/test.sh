#!/usr/bin/env bash

# place test file to into runtime
cp $2/my_file.fnl ~/config/fnl/my_file.fnl

cat <<EOF | assert "can import a fennel file without crashing"
  ~/test/nvim.sh "lua require('require_a_fnl_file.test')" || fail "could not import fennel file"
EOF

cat <<EOF | assert "imported file is in cache"
  if [[ ! -f ~/.cache/nvim/hotpot/compiled/config/lua/my_file.lua ]]; then
    exa --tree -a ~/.cache/nvim/hotpot >> ~/run.log
    fail "no cache file created"
  fi
EOF

