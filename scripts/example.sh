#!/usr/bin/env bash

docker run \
  -e RUNNABLE_AWS_ACCESS_KEY='AWS-ACCESS-KEY' \
  -e RUNNABLE_AWS_SECRET_KEY='AWS-SECRET-KEY'  \
  -e RUNNABLE_FILES_BUCKET='aws.bucket.name'  \
  -e RUNNABLE_PREFIX='source/' \
  -e RUNNABLE_FILES='{ "source/Dockerfile": "Po.EGeNr9HirlSJVMSxpf1gaWa5KruPa" }'  \
  -e RUNNABLE_KEYS_BUCKET='runnable.deploykeys'  \
  -e RUNNABLE_DEPLOYKEY='path/to/a/id_rsa'  \
  -e RUNNABLE_REPO='git@github.com:Runnable/image-builder'  \
  -e RUNNABLE_COMMITISH='master'  \
  -e RUNNABLE_DOCKER='tcp://192.168.59.103:2375' \
  -e RUNNABLE_DOCKERTAG='docker-tag' \
  -e RUNNABLE_DOCKER_BUILDOPTIONS='' \
  -v $HOME/cache:/cache:rw \
  docker-image-builder
