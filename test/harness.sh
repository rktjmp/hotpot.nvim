#!/usr/bin/env bash

podman_command=${1:-podman}
podman_flags=${2}

start_at=$(date +%s)

# build container, set parent dir as context so we can copy all of hotpot
echo "Building test image"
test_image_id=$($podman_command build $podman_flags --quiet -f ./Containerfile ../)
echo "Image id: $test_image_id"
# TODO check test_image_id not "" or whatever

kill_container() {
  $podman_command kill $1 > /dev/null
}

passed=0
failed=0

run_test_sh() {
  printf "Running test: $1..."

  # boot the container, mount the given test under /test and /test/lua
  container_id=$($podman_command run \
                  --rm -dit \
                  $test_image_id)

  # pass the name of the test, and the path of the test to the test file
  output=$($podman_command exec \
            $container_id \
            /home/user/test/$1/test.sh $1 /home/user/test/$1/)

  _hide=$($podman_command exec $container_id [ ! -f /home/user/fail ])

  if [ "$?" -eq "0" ]; then
    echo "PASS"
    passed=$((passed+1))
    while IFS= read -r line; do
      printf "=> $line\n"
    done <<< "$output"
    # log=$($podman_command exec $container_id cat /run.log)
    # echo "  !> $log"
  else
    echo "FAIL"
    failed=$((failed+1))
    while IFS= read -r line; do
      printf "  => $line\n"
    done <<< "$output"
#   sed -i -e 's/^/  \|/' test.log > test.log.new
    reason=$($podman_command exec $container_id cat /home/user/fail)
    echo "$reason"
    log=$($podman_command exec $container_id cat /home/user/run.log)
    echo "$log"
  fi

  kill_container $container_id
}

tests="require_hotpot \
       bootstrap \
       require_a_fnl_file \
       api \
       api-make \
       cache_invalidation \
       plugins \
       user_53_kebab_filename \
       nix_compat"
for name in $tests; do
  run_test_sh $name
done

finish_at=$(date +%s)
elapsed=$((finish_at - start_at))
total=$((passed+failed))
echo "FINISHED TESTS: $total, PASSED: $passed, FAILED: $failed, TIME: $elapsed seconds"

if [[ $failed -gt 0 ]]; then
  exit 1;
else
  exit 0;
fi
