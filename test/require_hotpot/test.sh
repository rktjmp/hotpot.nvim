#!/usr/bin/env bash

cat <<EOF | assert "require(hotpot) does not crash"
  /test/nvim.sh require_hotpot || fail
EOF
