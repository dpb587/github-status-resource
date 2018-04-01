#!/bin/sh

set -eu

DIR=$( dirname "$0" )/../..

set +e # error expected

BUILD_ID=123 $DIR/bin/out > $TMPDIR/resource-$$ 2> $TMPDIR/resource-$$.out <<EOF
{
  "params": {
    "description": "test-description",
    "commit": "$TMPDIR/commit",
    "state": "failed",
    "target_url": "https://ci.example.com/\$BUILD_ID/output"
  },
  "source": {
    "access_token": "test-token",
    "context": "test-context",
    "endpoint": "http://127.0.0.1:9192",
    "repository": "dpb587/test-repo"
  }
}
EOF

set -e

if ! grep -q '^FATAL: Invalid parameter: state: failed' $TMPDIR/resource-$$.out ; then
  echo "FAILURE: Missing error for state validation"
  cat $TMPDIR/resource-$$.out
  exit 1
fi
