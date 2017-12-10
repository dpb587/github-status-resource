#!/bin/sh

set -eu

DIR=$( dirname "$0" )/../..

cat <<EOF | nc -l -s 127.0.0.1 -p 9192 > $TMPDIR/http.req-$$ &
HTTP/1.0 200 OK

{
  "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
  "statuses": []
}
EOF

in_dir=$TMPDIR/status-$$

mkdir $in_dir

set +e

$DIR/bin/in "$in_dir" > $TMPDIR/resource-$$ 2>&1 <<EOF
{
  "version": {
    "commit": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
    "status": "2"
  },
  "source": {
    "access_token": "test-token",
    "context": "test-context",
    "endpoint": "http://127.0.0.1:9192",
    "repository": "dpb587/test-repo"
  }
}
EOF

exitcode=$?

set -e

if ! [ "1" == "$exitcode" ] ; then
  echo "FAILURE: Expected exit code 1"
  exit 1
fi

if ! grep -q 'Status not found on 6dcb09b5b57875f334f61aebed695e2e4193db5e' $TMPDIR/resource-$$ ; then
  echo "FAILURE: Unexpected failure message"
  cat $TMPDIR/resource-$$
  exit 1
fi
