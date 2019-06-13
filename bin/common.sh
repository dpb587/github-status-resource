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
    ATC_EXTERNAL_URL="${ATC_EXTERNAL_URL:-}" \
    $envsubst
}

curlgh () {
  if $skip_ssl_verification; then
    skip_verify_arg="-k"
  else
    skip_verify_arg=""
  fi

  attempts=0
  maxAttempts=4
  sleepDuration=1
  while [[ $attempts -lt $maxAttempts ]]; do
    attempts=$((attempts+=1))
    curl $skip_verify_arg -s -D/tmp/responseheaders -H "Authorization: token $source_access_token" $@ > /tmp/rawresponse

    httpStatus=$(head -n1 /tmp/responseheaders | sed 's|HTTP.* \([0-9]*\) .*|\1|')
    if [[ "$httpStatus" -eq "200" ]]; then # If HTTP status is OK, skip to extracting the statuses
      break;
    fi

    # Various error handling (authn, authz, rate-limiting, transient API errors)
    if [[ "$httpStatus" -ge 400 ]]; then
      if [[ "$httpStatus" -lt 500 ]]; then # 4XX range
        if [[ $(grep -i 'rate-limit' /tmp/rawresponse || echo '0') -ge 1 ]]; then
          now=$(date "+%s")
          ratelimitReset=$(cat /tmp/responseheaders | sed -n 's|X-RateLimit-Reset: \([0-9]*\)|\1|p')

          sleepDuration=$((ratelimitReset-now))
          if [[ "$sleepDuration" -lt 1 ]]; then # Protects against timing issue
            sleepDuration=1
          fi
          echo "Limited by the API rate limit. Script will retry at $(date -d@$((now+sleepDuration)))" >&2
        else
          fatal "Authentication error against the GitHub API"
        fi
      else # 5XX range
        echo "Unexpected HTTP $(echo $httpStatus) when querying the GitHub API" >&2
        sleepDuration=5
      fi
    else # Other status code that's not 200 OK, nor in the 400+ range
      fatal "Unexpected HTTP status code when querying the GitHub API: $(echo $httpStatus)"
    fi

    # Exit if we have reach the maximum number of attemps, or sleep and retry otherwise
    if [[ $attempts -eq $maxAttempts ]]; then
      fatal "Maximum number of attempts reached while trying to query the GitHub API"
    else
      echo "Will retry in $sleepDuration seconds" >&2
      sleep $sleepDuration
    fi

  done

  cat /tmp/rawresponse
}
