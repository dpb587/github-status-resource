#!/bin/sh

set -eu

DIR=$( dirname "$0" )/../..

cat <<EOF | nc -l -s 127.0.0.1 -p 9192 > http.req &
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
      "updated_at": "2012-08-20T01:19:13Z",
      "state": "success",
      "target_url": "https://ci.example.com/2000/output",
      "description": "Testing has completed successfully",
      "id": 2,
      "url": "https://api.github.com/repos/octocat/Hello-World/statuses/2",
      "context": "security/brakeman"
    }
  ],
  "repository": {},
  "commit_url": "https://api.github.com/repos/octocat/Hello-World/6dcb09b5b57875f334f61aebed695e2e4193db5e",
  "url": "https://api.github.com/repos/octocat/Hello-World/6dcb09b5b57875f334f61aebed695e2e4193db5e/status"
}
EOF

in_dir=/tmp/status-$$

mkdir $in_dir

$DIR/bin/in "$in_dir" > /tmp/resource <<EOF
{
  "version": {
    "ref": "2"
  },
  "source": {
    "access_token": "test-token",
    "context": "test-context",
    "endpoint": "http://127.0.0.1:9192",
    "repository": "dpb587/test-repo"
  }
}
EOF

grep -q '^GET /repos/dpb587/test-repo/commits/master/status ' http.req \
  || ( echo "FAILURE: Invalid HTTP method or URI" ; cat http.* ; exit 1 )

[[ "6dcb09b5b57875f334f61aebed695e2e4193db5e" == "$( cat $in_dir/commit )" ]] \
  || ( echo "FAILURE: Unexpected /commit data" ; cat "$in_dir/commit" ; exit 1 )

[[ "Testing has completed successfully" == "$( cat $in_dir/description )" ]] \
  || ( echo "FAILURE: Unexpected /description data" ; cat "$in_dir/description" ; exit 1 )

[[ "success" == "$( cat $in_dir/state )" ]] \
  || ( echo "FAILURE: Unexpected /state data" ; cat "$in_dir/state" ; exit 1 )

[[ "https://ci.example.com/2000/output" == "$( cat $in_dir/target_url )" ]] \
  || ( echo "FAILURE: Unexpected /target_url data" ; cat "$in_dir/target_url" ; exit 1 )

[[ "2012-08-20T01:19:13Z" == "$( cat $in_dir/updated_at )" ]] \
  || ( echo "FAILURE: Unexpected /updated_at data" ; cat "$in_dir/updated_at" ; exit 1 )

grep -q '"version":{"ref":"2"}' /tmp/resource \
  || ( echo "FAILURE: Unexpected version output" ; cat /tmp/resource ; exit 1 )

grep -q '{"name":"created_at","value":"2012-08-20T01:19:13Z"}' /tmp/resource \
  || ( echo "FAILURE: Unexpected created_at output" ; cat /tmp/resource ; exit 1 )
