FROM alpine

RUN apk add --update python py-pip python-dev \
  && apk add --update git \
  && pip install requests GitPython

ADD bin /opt/resource
