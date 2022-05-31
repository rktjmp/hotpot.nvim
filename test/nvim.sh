#!/usr/bin/env bash
output=$(nvim -Es -u ~/test/init.lua -c "$1")

if [[ "$?" -eq "0" ]]; then
  exit 0
else
  echo $output
  exit 1
fi
