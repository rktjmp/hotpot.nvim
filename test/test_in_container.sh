#!/usr/bin/env bash
set -eu

# podman_command=${1:-podman}
# podman_flags=${2:-}
podman_command=podman
podman_flags=""
only_test=${1:-}
start_at=$(date +%s)
failed=0

echo "Building test image"
test_image_id=$($podman_command build $podman_flags --quiet \
                --ignorefile ./test/Containerignore \
                -f ./test/Containerfile .)
echo "Image id: $test_image_id"

echo "Running tests in $test_image_id"
$podman_command run --rm -it $test_image_id test/test.sh $only_test
failed=$?

# finish_at=$(date +%s)
# elapsed=$((finish_at - start_at))
# total=$((passed+failed))
# echo "FINISHED TESTS: $total, PASSED: $passed, FAILED: $failed, TIME: $elapsed seconds"

exit $failed
