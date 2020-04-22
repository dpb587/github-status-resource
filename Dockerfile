FROM alpine
RUN apk --no-cache add curl ca-certificates gettext \
  && curl -Ls https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 > /usr/bin/jq && chmod +x /usr/bin/jq
ADD bin /opt/resource
