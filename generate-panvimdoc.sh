#!/usr/bin/env bash

IMAGE=hotpot-panvimdoc

podman build -t $IMAGE -f - <<EOF
FROM alpine:latest
RUN apk add --no-cache pandoc git bash neovim
RUN mkdir /data
RUN mkdir /panvimdoc && \
    cd /panvimdoc && \
    git clone https://github.com/kdheepak/panvimdoc.git .
WORKDIR /data
ENTRYPOINT ["/panvimdoc/panvimdoc.sh"]
EOF

podman run --rm -v .:/data hotpot-panvimdoc \
  --project-name "hotpot" \
  --input-file README.md \
  --demojify true \
  --doc-mapping true


