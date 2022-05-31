#/usr/bin/env bash

# moved to /usr/bin/assert in container

# dont start if already failed
if [[ -f ~/fail ]]; then
  exit 1
fi

echo "starting $1" >> ~/test.log

echo "  +>" > ~/fail.head
echo "  +> ASSERT $1" >> ~/fail.head
output=$(bash < /dev/stdin 1>> ~/run.log 2>> ~/run.log)

if [[ -f ~/fail ]]; then
  echo "FAIL $1"
  mv ~/fail ~/fail.tail
  cat ~/fail.head > ~/fail
  cat ~/fail.tail >> ~/fail
  echo "  +>" >> ~/fail
output=$(bash < /dev/stdin 1>> ~/run.log 2>> ~/run.log)
  rm ~/fail.head ~/fail.tail
  exit 1
else
  rm ~/fail.head
  echo "PASS $1"
  exit 0
fi
