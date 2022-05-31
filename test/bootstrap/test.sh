#!/usr/bin/env bash
canary=$(ls ~/hotpot/canary)

cat <<EOF | assert "ships with a canary"
  if [[ ! -f ~/hotpot/canary/$canary ]]; then
    fail "missing canary"
  fi
EOF

cat <<EOF | assert "links the canary to the install on first compile"
  ~/test/nvim.sh "lua require('bootstrap.test')" || fail "could not require bootstrap.test.lua"
  if [[ ! -f ~/hotpot/lua/canary ]]; then
    ls -la ~/hotpot/lua/ >> ~/run.log
    fail "no link created"
  fi
EOF

cat <<EOF | assert "it produces some compiled output"
  if [[ ! -f ~/hotpot/lua/hotpot/runtime.lua ]]; then
    exa --tree -a ~/hotpot/lua >> ~/run.log
    exa --tree -a ~ >> ~/run.log
    fail "missing runtime.lua"
  fi
EOF
