#!/usr/bin/env bash
set -e

# Make a working directory
TEMPDIR=$(mktemp -d /tmp/rnnbl.XXXXXXXXXXXXXXXXXXXX)

if [ ! "$RUNNABLE_AWS_ACCESS_KEY" ] || [ ! "$RUNNABLE_AWS_SECRET_KEY" ]; then
  echo "need both AWS credentials..."
  exit 1
fi

# GET DEPLOY KEY ($RUNNABLE_DEPLOYKEY)
TEMPKEY=$(mktemp -d /tmp/rnnbl.key.XXXXXXXXXXXXXXXXXXXX)
if [ "$RUNNABLE_DEPLOYKEY" ]; then
  echo "downloading deploy key..."
  node downloadS3Files.js \
    --bucket "$RUNNABLE_KEYS_BUCKET" \
    --file "$RUNNABLE_DEPLOYKEY" \
    --dest "$TEMPKEY"
  if [ "$(ssh-add > /dev/null 2>&1)" != "0" ]; then
    eval $(ssh-agent) > /dev/null
  fi
  chmod 600 "$TEMPKEY"/"$RUNNABLE_DEPLOYKEY"
  ssh-add "$TEMPKEY"/"$RUNNABLE_DEPLOYKEY"
fi

# GIT CLONE
REPO_DIR=$(echo "$RUNNABLE_REPO" | awk '{split($0,r,"/"); if (r[1] == "https:") print r[5]; else print r[2];}')
if [ "$RUNNABLE_REPO" ]; then
  echo "downloading repository..."
  pushd $TEMPDIR > /dev/null
  git clone "$RUNNABLE_REPO" "$REPO_DIR"
  if [ "$RUNNABLE_COMMITISH" ]; then
    pushd $REPO_DIR > /dev/null
    git checkout "$RUNNABLE_COMMITISH"
    popd
  fi
  popd > /dev/null
fi

# S3 DOWNLOAD
if [ "$RUNNABLE_FILES" ]; then
  echo "downloading build files..."
  node downloadS3Files.js \
    --bucket "$RUNNABLE_FILES_BUCKET" \
    --files "$RUNNABLE_FILES" \
    --prefix "$RUNNABLE_PREFIX" \
    --dest "$TEMPDIR"
fi

# DOCKER BUILD
if [ "$RUNNABLE_DOCKER" ] && [ "$RUNNABLE_DOCKERTAG" ]; then
  echo "docker build..."
  docker -H\="$RUNNABLE_DOCKER" build \
    -t "$RUNNABLE_DOCKERTAG" \
    $RUNNABLE_DOCKER_BUILDOPTIONS \
    "$TEMPDIR"
fi

echo "done!"
