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
    "source_base_context": ( .source.base_context // "concourse-ci" ),
    "source_context": ( .source.context // "default" ),
    "source_endpoint": ( .source.endpoint // "https://api.github.com" ),
    "skip_ssl_verification": ( .source.skip_ssl_verification // "false" )
    } | to_entries[] | .key + "=" + @sh "\(.value)"
  ' < /tmp/stdin )

  source_endpoint=$( echo "$source_endpoint" | sed 's#/$##' )
}

buildtpl () {
  envsubst=$( which envsubst )
  env -i \
    BUILD_ID="${BUILD_ID:-}" \
    BUILD_NAME="${BUILD_NAME:-}" \
    BUILD_JOB_NAME="${BUILD_JOB_NAME:-}" \
    BUILD_PIPELINE_NAME="${BUILD_PIPELINE_NAME:-}" \
    BUILD_TEAM_NAME="${BUILD_TEAM_NAME:-}" \
    ATC_EXTERNAL_URL="${ATC_EXTERNAL_URL:-}" \
    $envsubst
}

curlgh () {
  if $skip_ssl_verification; then
    skip_verify_arg="-k"
  else
    skip_verify_arg=""
  fi
  curl $skip_verify_arg -s -H "Authorization: token $source_access_token" $@
}

curlgh_all_pages_status () {
    results=''
    page=1
    present='true'
    while [ "$present" = "true" ]; do
        current_results=$(curlgh "$@?page=$page")

        # If key "statuses" is not present, stop iterating loop
        statuses=$(echo $current_results | jq -c '.statuses // []')
        if [ "$statuses" != "[]" ]; then
            # Identify "statuses" array in `current_results` and append it to "statuses" array in `results`
            results=$(echo "$results" | jq --argjson s "$statuses" '.statuses += $s')
            page=$(($page+1))
        else
            present='false'
        fi
    done

    echo "$results"
}
