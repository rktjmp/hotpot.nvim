#!/usr/bin/env bash

cat <<EOF | assert "can require fennel via api"
  /test/nvim.sh $1 || fail
EOF
