#!/bin/sh

set -eu

DIR=$( dirname "$0" )/../..

cat <<EOF | nc -l -s 127.0.0.1 -p 9192 > $TMPDIR/http.req-$$ &
HTTP/1.0 200 OK

{
  "state": "success",
  "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
  "total_count": 2,
  "statuses": [
    {
      "created_at": "2012-07-20T01:19:13Z",
      "updated_at": "2012-07-20T01:19:13Z",
      "state": "success",
      "target_url": "https://ci.example.com/1000/output",
      "description": "Build has completed successfully",
      "id": 1,
      "url": "https://api.github.com/repos/octocat/Hello-World/statuses/1",
      "context": "continuous-integration/jenkins"
    },
    {
      "created_at": "2012-08-20T01:19:13Z",
      "updated_at": "2012-08-20T02:19:13Z",
      "state": "success",
      "target_url": "https://ci.example.com/2000/output",
      "description": "Testing has completed successfully",
      "id": 2,
      "url": "https://api.github.com/repos/octocat/Hello-World/statuses/2",
      "context": "test-context"
    }
  ]
}
EOF

$DIR/bin/check > $TMPDIR/resource-$$ <<EOF
{
  "source": {
    "access_token": "test-token",
    "branch": "pr-test",
    "context": "test-context",
    "endpoint": "http://127.0.0.1:9192",
    "repository": "dpb587/test-repo"
  }
}
EOF

grep -q '^GET /repos/dpb587/test-repo/commits/pr-test/status ' $TMPDIR/http.req-$$ \
  || ( echo "FAILURE: Invalid HTTP method or URI" ; $TMPDIR/http.req-$$ ; exit 1 )

[[ '[{"ref":"2"}]' == "$( cat $TMPDIR/resource-$$ )" ]] \
  || ( echo "FAILURE: Unexpected version output" ; cat $TMPDIR/resource-$$ ; exit 1 )
