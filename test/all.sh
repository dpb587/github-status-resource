#!/bin/sh

failed=false

dir=$( dirname "$0" )/..
cd $dir

export TMPDIR="${TMPDIR:-/tmp}"

for test in $( find test -type f -print | grep -v 'test/all.sh' ) ; do
  echo "==> $test"
  $test
  result=$?

  echo

  [[ "0" == "$result" ]] || failed=true
done

[[ "false" == "$failed" ]] || exit 1
