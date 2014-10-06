#!/usr/bin/env bash

mkdir -p ./test-02/flaming-octo-nemesis
mkdir -p ./test-02/flaming-octo-nemesis.lock

docker run \
  -e RUNNABLE_AWS_ACCESS_KEY="$AWS_ACCESS_KEY" \
  -e RUNNABLE_AWS_SECRET_KEY="$AWS_SECRET_KEY" \
  -e RUNNABLE_FILES_BUCKET='runnable.image-builder' \
  -e RUNNABLE_PREFIX='' \
  -e RUNNABLE_FILES='{ "Dockerfile": "K6cluDupwQdFRsuTPJ0SFUrxUB4lmF_Q" }' \
  -e RUNNABLE_KEYS_BUCKET='runnable.image-builder' \
  -e RUNNABLE_DEPLOYKEY='flaming-octo-nemesis.key' \
  -e RUNNABLE_REPO='git@github.com:bkendall/flaming-octo-nemesis' \
  -e RUNNABLE_COMMITISH='master' \
  -e RUNNABLE_DOCKER="$(cat DOCKER_IP):5354" \
  -e RUNNABLE_DOCKERTAG='test-built-image' \
  -e RUNNABLE_DOCKER_BUILDOPTIONS='' \
  -v `pwd`/test-02:/cache:rw \
  test-image-builder
