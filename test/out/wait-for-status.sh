
#!/bin/sh

response_after_creation() {
  cat <<EOF | nc -l -s 127.0.0.1 -p 9192 > $TMPDIR/http.req-$$
HTTP/1.0 200 OK

{
  "created_at": "2012-07-20T01:19:13Z",
  "updated_at": "2012-07-20T02:19:13Z",
  "state": "success",
  "target_url": "https://ci.example.com/1000/output",
  "description": "Build has completed successfully",
  "id": 1,
  "url": "https://api.github.com/repos/octocat/Hello-World/statuses/1",
  "context": "continuous-integration/jenkins",
  "creator": {
    "login": "octocat",
    "id": 1,
    "avatar_url": "https://github.com/images/error/octocat_happy.gif",
    "gravatar_id": "",
    "url": "https://api.github.com/users/octocat",
    "html_url": "https://github.com/octocat",
    "followers_url": "https://api.github.com/users/octocat/followers",
    "following_url": "https://api.github.com/users/octocat/following{/other_user}",
    "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
    "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
    "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
    "organizations_url": "https://api.github.com/users/octocat/orgs",
    "repos_url": "https://api.github.com/users/octocat/repos",
    "events_url": "https://api.github.com/users/octocat/events{/privacy}",
    "received_events_url": "https://api.github.com/users/octocat/received_events",
    "type": "User",
    "site_admin": false
  }
}
EOF
}

response_with_status() {
  cat <<EOF | nc -l -s 127.0.0.1 -p 9192 > /dev/null
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
}

response_without_status() {
  cat <<EOF | nc -l -s 127.0.0.1 -p 9192 > /dev/null
HTTP/1.0 200 OK

{
  "state": "success",
  "sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
  "total_count": 1,
  "statuses": [
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
}

sequential_responses() {
  response_after_creation
  response_without_status
  response_with_status
}

set -eu

DIR=$( dirname "$0" )/../..

echo 'a1b2c3d4e5' > $TMPDIR/commit

sequential_responses &

BUILD_ID=123 $DIR/bin/out > $TMPDIR/resource-$$ <<EOF
{
  "params": {
    "description": "test-description",
    "commit": "$TMPDIR/commit",
    "state": "success",
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

if ! grep -q '^POST /repos/dpb587/test-repo/statuses/a1b2c3d4e5 ' $TMPDIR/http.req-$$ ; then
  echo "FAILURE: Invalid HTTP method or URI"
  cat $TMPDIR/http.req-$$
  exit 1
fi

if ! grep -q '^{"context":"concourse-ci/test-context","description":"test-description","state":"success","target_url":"https://ci.example.com/123/output"}$' $TMPDIR/http.req-$$ ; then
  echo "FAILURE: Unexpected request body"
  cat $TMPDIR/http.req-$$
  exit 1
fi

if ! grep -q '"version":{"commit":"a1b2c3d4e5","status":"1"}' $TMPDIR/resource-$$ ; then
  echo "FAILURE: Unexpected version output"
  cat $TMPDIR/resource-$$
  exit 1
fi

if ! grep -q '{"name":"created_at","value":"2012-07-20T01:19:13Z"}' $TMPDIR/resource-$$ ; then
  echo "FAILURE: Unexpected created_at output"
  cat $TMPDIR/resource-$$
  exit 1
fi

if ! grep -q '{"name":"created_by","value":"octocat"}' $TMPDIR/resource-$$ ; then
  echo "FAILURE: Unexpected creator output"
  cat $TMPDIR/resource-$$
  exit 1
fi
