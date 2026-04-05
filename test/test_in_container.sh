#!/usr/bin/env bash
set -eu

# podman_command=${1:-podman}
# podman_flags=${2:-}
podman_command=podman
podman_flags=""
only_test=${1:-}
NVIM_VERSION=${NVIM_VERSION:-v0.11.7}
start_at=$(date +%s)
failed=0

echo "Building test image"
test_image_id=$($podman_command build $podman_flags --quiet \
                --ignorefile ./test/Containerignore \
                --build-arg NVIM_VERSION=$NVIM_VERSION \
                -f ./test/Containerfile .)
echo "Image id: $test_image_id"

echo "Running tests in $test_image_id"
$podman_command run --rm \
  --env NVIM_BIN=nvim \
  $test_image_id test/test.sh $only_test
failed=$?

exit $failed
