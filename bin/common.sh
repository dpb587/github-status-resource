#!/bin/sh

set -eu

[ ! -e /tmp/build/* ] || cd /tmp/build/*

REM () {
  /bin/echo $( date -u +"%Y-%m-%dT%H:%M:%SZ" ) "$@"
}

fatal () {
  echo "FATAL: $1" >&2
  exit 1
}

repipe () {
  exec 3>&1
  exec 1>&2
  cat > /tmp/stdin
}

load_source () {
  eval $( jq -r '{
    "source_repository": .source.repository,
    "source_access_token": .source.access_token,
    "source_branch": ( .source.branch // "master" ),
    "source_context": ( .source.context // "default" ),
    "source_endpoint": ( .source.endpoint // "https://api.github.com" )
    } | to_entries[] | .key + "=" + @sh "\(.value)"
  ' < /tmp/stdin )
}

buildtpl () {
  envsubst=$( which envsubst )
  env -i \
    BUILD_ID="${BUILD_ID:-}" \
    BUILD_NAME="${BUILD_NAME:-}" \
    BUILD_JOB_NAME="${BUILD_JOB_NAME:-}" \
    BUILD_PIPELINE_NAME="${BUILD_PIPELINE_NAME:-}" \
    ATC_EXTERNAL_URL="${ATC_EXTERNAL_URL:-}" \
    $envsubst
}

curlgh () {
  curl -s -H "Authorization: token $source_access_token" $@
}
