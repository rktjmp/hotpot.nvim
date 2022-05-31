#!/usr/bin/env bash

cat <<EOF | assert "can require fennel via api"
  ~/test/nvim.sh "lua require('test.api.fennel')" || fail
EOF

cat <<EOF | assert "can run :Fnl <expression>"
  ~/test/nvim.sh "Fnl (+ 1 1)" || fail
EOF

cat <<EOF | assert "can run :Fnl with range"
  ~/test/nvim.sh "e ~/test/api/cmd_fnl.fnl | 2,2Fnl" || fail
EOF

cat <<EOF | assert "can run :Fnlfile"
  ~/test/nvim.sh "Fnlfile ~/test/api/fnlfile.fnl" || fail
EOF

# fnldo is a bit awkward to test.
