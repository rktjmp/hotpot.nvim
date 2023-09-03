#!/usr/bin/env bash

# place test file to into runtime
cp $2/plugin.fnl ~/config/fnl/plugin.fnl
cp $2/force_compile.fnl ~/config/fnl/force_compile.fnl

cat <<EOF | assert "can import a fennel file without crashing"
  ~/test/nvim.sh "lua require('plugins.test')" || fail "could not require plugins.test.lua"
EOF
