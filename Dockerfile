FROM alpine

RUN apk --no-cache add curl ca-certificates gettext \
  && curl -Ls https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 > /usr/bin/jq \
  && chmod +x /usr/bin/jq

RUN apk add --update bash && rm -rf /var/cache/apk/*

ADD bin /opt/resource
