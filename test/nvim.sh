#!/usr/bin/env bash
output=$(nvim -Es -u /test/init.lua -c "lua require('$1.test')")

if [[ "$?" -eq "0" ]]; then
  exit 0
else
  echo $output
  exit 1
fi
