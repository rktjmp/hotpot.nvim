#/usr/bin/env bash
# moved to /usr/bin/fail in container
touch ~/fail
echo "  +> REASON: $1" >> ~/fail
