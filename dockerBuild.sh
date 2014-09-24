#!/usr/bin/env bash
set -e

# Seperator for lists
IFS=";"

# Make a working directory
TEMPDIR=$(mktemp -d /tmp/rnnbl.XXXXXXXXXXXXXXXXXXXX)

if [ ! "$RUNNABLE_AWS_ACCESS_KEY" ] || [ ! "$RUNNABLE_AWS_SECRET_KEY" ]; then
  echo "\e[1m\e[91mMissing credentials.\e[0m"
  exit 1
fi

# GET DEPLOY KEY ($RUNNABLE_DEPLOYKEY)
TEMPKEYDIR=$(mktemp -d /tmp/rnnbl.key.XXXXXXXXXXXXXXXXXXXX)
read -a KEY_ARRAY <<< "$RUNNABLE_DEPLOYKEY"
if [ "$RUNNABLE_DEPLOYKEY" ]; then
  if [ "$(ssh-add > /dev/null 2>&1)" != "0" ]; then
    eval $(ssh-agent) > /dev/null
  fi
  for KEY in $RUNNABLE_DEPLOYKEY; do
    node downloadS3Files.js \
      --bucket "$RUNNABLE_KEYS_BUCKET" \
      --file "$KEY" \
      --dest "$TEMPKEYDIR" > /dev/null
    chmod 600 "$TEMPKEYDIR"/"$KEY"
  done
fi

# GIT CLONE
read -a REPO_ARRAY <<< "$RUNNABLE_REPO"
read -a COMMITISH_ARRAY <<< "$RUNNABLE_COMMITISH"
for index in "${!REPO_ARRAY[@]}"
do
  REPO_DIR=$(echo "\e[1m\e[93m${REPO_ARRAY[index]}\e[0m" | awk '{split($0,r,"/"); print r[2];}')
  REPO_FULL_NAME=$(echo "\e[1m\e[93m${REPO_ARRAY[index]}\e[0m" | awk '{split($0,r,":"); print r[2];}')
  echo "\e[1m\e[93mCloning '$REPO_FULL_NAME' into './$REPO_DIR'...\e[0m"
  pushd $TEMPDIR > /dev/null
  ssh-add -D > /dev/null 2>&1
  ssh-add "$TEMPKEYDIR"/"${KEY_ARRAY[index]}" > /dev/null 2>&1
  git clone -q "${REPO_ARRAY[index]}" "$REPO_DIR"
  if [ "$RUNNABLE_COMMITISH" ]; then
    pushd $REPO_DIR > /dev/null
    git checkout -q "${COMMITISH_ARRAY[index]}"
    popd > /dev/null
  fi
  popd > /dev/null
  echo ""
done

# S3 DOWNLOAD
if [ "$RUNNABLE_FILES" ]; then
  echo "\e[1m\e[93mDownloading build files...\e[0m"
  node downloadS3Files.js \
    --bucket "$RUNNABLE_FILES_BUCKET" \
    --files "$RUNNABLE_FILES" \
    --prefix "$RUNNABLE_PREFIX" \
    --dest "$TEMPDIR"
  echo ""
fi

# DOCKER BUILD
if [ "$RUNNABLE_DOCKER" ] && [ "$RUNNABLE_DOCKERTAG" ]; then
  echo "\e[1m\e[93mBuilding box...\e[0m"
  docker -H\="$RUNNABLE_DOCKER" build \
    -t "$RUNNABLE_DOCKERTAG" \
    $RUNNABLE_DOCKER_BUILDOPTIONS \
    "$TEMPDIR"
  echo ""
fi

echo "\e[1m\e[92mBuild completed successfully!\e[0m"
