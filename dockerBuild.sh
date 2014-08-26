#!/usr/bin/env bash
set -e

# Seperator for lists
IFS=";"

# Make a working directory
TEMPDIR=$(mktemp -d /tmp/rnnbl.XXXXXXXXXXXXXXXXXXXX)

if [ ! "$RUNNABLE_AWS_ACCESS_KEY" ] || [ ! "$RUNNABLE_AWS_SECRET_KEY" ]; then
  echo "need both AWS credentials..."
  exit 1
fi

# GET DEPLOY KEY ($RUNNABLE_DEPLOYKEY)
TEMPKEYDIR=$(mktemp -d /tmp/rnnbl.key.XXXXXXXXXXXXXXXXXXXX)
if [ "$RUNNABLE_DEPLOYKEY" ]; then
  if [ "$(ssh-add > /dev/null 2>&1)" != "0" ]; then
    eval $(ssh-agent) > /dev/null
  fi
  for KEY in $RUNNABLE_DEPLOYKEY; do
    echo "downloading deploy key..."
    node downloadS3Files.js \
      --bucket "$RUNNABLE_KEYS_BUCKET" \
      --file "$KEY" \
      --dest "$TEMPKEYDIR"
    chmod 600 "$TEMPKEYDIR"/"$KEY"
    ssh-add "$TEMPKEYDIR"/"$KEY"
  done
fi

# GIT CLONE
read -a REPO_ARRAY <<< "$RUNNABLE_REPO"
read -a COMMITISH_ARRAY <<< "$RUNNABLE_COMMITISH"
for index in "${!REPO_ARRAY[@]}"
do
  echo "$index ${REPO_ARRAY[index]}"
  REPO_DIR=$(echo "${REPO_ARRAY[index]}" | awk '{split($0,r,"/"); if (r[1] == "https:") print r[5]; else print r[2];}')
  echo "downloading repository... ${REPO_ARRAY[index]}"
  pushd $TEMPDIR > /dev/null
  git clone "${REPO_ARRAY[index]}" "$REPO_DIR"
  if [ "$RUNNABLE_COMMITISH" ]; then
    pushd $REPO_DIR > /dev/null
    git checkout "${COMMITISH_ARRAY[index]}"
    popd > /dev/null
  fi
  popd > /dev/null
done

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
