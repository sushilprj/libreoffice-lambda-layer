#!/bin/bash -x

set -e

rm -rf layer && mkdir -p layer/lib && mkdir -p layer/ruby/gems

docker build --force-rm=true --rm=true --no-cache -t lambda-libreoffice-builder -f Dockerfile . 

CONTAINER=$(docker run -dit bash lambda-libreoffice-builder false)

docker cp \
    $CONTAINER:/var/task/vendor/bundle/ruby/2.5.0 \
    layer/ruby/gems/2.5.0

docker rm $CONTAINER