#!/usr/bin/env bash

cat <<EOF | assert "require(hotpot) does not crash"
  /test/nvim.sh "lua require('require_hotpot.test')" || fail
EOF
