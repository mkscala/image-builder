#!/usr/bin/env bash
set -e

# Seperator for lists
IFS=";"
STYLE_BOLD="\e[1m"
STYLE_RESET="\e[0m"
COLOR_STATUS="\e[93m"
COLOR_ERROR="\e[91m"
COLOR_SUCCESS="\e[92m"

# Make a working directory
TEMPDIR=$(mktemp -d /tmp/rnnbl.XXXXXXXXXXXXXXXXXXXX)

if [ ! "$RUNNABLE_AWS_ACCESS_KEY" ] || [ ! "$RUNNABLE_AWS_SECRET_KEY" ]; then
  echo "${STYLE_BOLD}${COLOR_ERROR}Missing credentials.${STYLE_RESET}"
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
  REPO_DIR=$(echo "${STYLE_BOLD}${COLOR_STATUS}${REPO_ARRAY[index]}${STYLE_RESET}" | awk '{split($0,r,"/"); print r[2];}')
  REPO_FULL_NAME=$(echo "${STYLE_BOLD}${COLOR_STATUS}${REPO_ARRAY[index]}${STYLE_RESET}" | awk '{split($0,r,":"); print r[2];}')
  echo "${STYLE_BOLD}${COLOR_STATUS}Cloning '$REPO_FULL_NAME' into './$REPO_DIR'...${STYLE_RESET}"
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
  echo "${STYLE_BOLD}${COLOR_STATUS}Downloading build files...${STYLE_RESET}"
  node downloadS3Files.js \
    --bucket "$RUNNABLE_FILES_BUCKET" \
    --files "$RUNNABLE_FILES" \
    --prefix "$RUNNABLE_PREFIX" \
    --dest "$TEMPDIR"
  echo ""
fi

# DOCKER BUILD
if [ "$RUNNABLE_DOCKER" ] && [ "$RUNNABLE_DOCKERTAG" ]; then
  echo "${STYLE_BOLD}${COLOR_STATUS}Building box...${STYLE_RESET}"
  docker -H\="$RUNNABLE_DOCKER" build \
    -t "$RUNNABLE_DOCKERTAG" \
    $RUNNABLE_DOCKER_BUILDOPTIONS \
    "$TEMPDIR"
  echo ""
fi

echo "${STYLE_BOLD}${COLOR_SUCCESS}Build completed successfully!${STYLE_RESET}"
