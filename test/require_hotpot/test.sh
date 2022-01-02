#!/usr/bin/env bash

cat <<EOF | assert "require(hotpot) does not crash"
  /test/nvim.sh $1 || fail
EOF
