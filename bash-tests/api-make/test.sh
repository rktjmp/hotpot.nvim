#!/usr/bin/env bash

cat <<EOF | assert "can build"
  ~/test/nvim.sh "lua require('test.api-make.test-make')" || fail something

  if [[ ! -f ~/test/api-make/lua/a.lua ]]; then
    ls -la ~/test/api-make/lua/ >> ~/run.log
    fail "no a.lua created"
  fi

  if [[ ! -f ~/test/api-make/lua/b.lua ]]; then
    ls -la ~/test/api-make/lua/ >> ~/run.log
    fail "no b.lua created"
  fi

  if [[ -f ~/test/api-make/lua/dont.lua ]]; then
    ls -la ~/test/api-make/lua/ >> ~/run.log
    fail "dont.lua *was* created"
  fi
EOF
