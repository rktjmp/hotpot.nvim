#!/usr/bin/env bash
canary=$(ls ~/hotpot/canary)

# set unwritable checkout
chmod -R -w ~/hotpot

cat <<EOF | assert "ships with a canary"
  if [[ ! -f ~/hotpot/canary/$canary ]]; then
    fail "missing canary"
  fi
EOF

cat <<EOF | assert "ships without canary link"
  if [[ -f ~/hotpot/lua/canary ]]; then
    fail "existing canary"
  fi
EOF

~/test/nvim.sh "lua require('bootstrap.test')" || fail "could not require bootstrap.test.lua"
cat <<EOF | assert "does not create canary in shipped dir"
  if [[ -f ~/hotpot/lua/canary ]]; then
    exa --tree -l ~/hotpot/lua >> ~/run.log
    fail "link created in shiped lua folder"
  fi
EOF

cat <<EOF | assert "does create canary in cache dir"
  if [[ ! -f ~/.cache/nvim/hotpot/compiled/hotpot.nvim/lua/canary ]]; then
    exa --tree -l ~/.cache/nvim/hotpot >> ~/run.log
    fail "no link created in cache lua folder"
  fi
EOF

cat <<EOF | assert "does not create lua in shipped dir"
  if [[ -f ~/hotpot/lua/hotpot/runtime.lua ]]; then
    exa --tree -l ~/hotpot/lua >> ~/run.log
    fail "created lua in shiped lua folder"
  fi
EOF

cat <<EOF | assert "does create lua in cache dir"
  if [[ ! -f ~/.cache/nvim/hotpot/compiled/hotpot.nvim/lua/hotpot/runtime.lua ]]; then
    exa --tree -l ~/.cache/nvim/hotpot >> ~/run.log
    fail "no lua created in cache lua folder"
  fi
EOF
