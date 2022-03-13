#!/usr/bin/env bash
canary=$(ls /hotpot/canary)

cat <<EOF | assert "ships with a canary"
  if [[ ! -f /hotpot/canary/$canary ]]; then
    fail "missing canary"
  fi
EOF

cat <<EOF | assert "links the canary to the install on first compile"
  /test/nvim.sh bootstrap || fail "coult not require bootstrap.test.lua"
  if [[ ! -f /root/.cache/nvim/hotpot/canary ]]; then
    ls -la /root/.cache/nvim/hotpot/ >> /run.log
    fail "no link created"
  fi
EOF

# path here is a bit funny
# /root/.cache/nvim/hotpot <- the cache root
# /root/.cache/nvim/hotpot/hotpot <- git repo root ("hotpot install location")
# /root/.cache/nvim/hotpot/hotpot/fnl/hotpot <- hotpot module folder ("require hotpot.x") 
cat <<EOF | assert "it produces some compiled output"
  if [[ ! -f /root/.cache/nvim/hotpot/hotpot/fnl/hotpot/runtime.lua ]]; then
    exa --tree -a /root/.cache >> /run.log
    fail "missing runtime.lua"
  fi
EOF
