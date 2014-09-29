#!/usr/bin/env bash
set -e

# Seperator for lists
IFS_BAK=$IFS
IFS=";"
# Echo colors
STYLE_BOLD="\033[1m"
STYLE_RESET="\033[0m"
COLOR_STATUS="\033[93m"
COLOR_ERROR="\033[91m"
COLOR_SUCCESS="\033[92m"
# This directory
BUILDER_LIB_DIR=$(pwd)

# Make a working directory
TEMPDIR=$(mktemp -d /tmp/rnnbl.XXXXXXXXXXXXXXXXXXXX)

if [ ! "$RUNNABLE_AWS_ACCESS_KEY" ] || [ ! "$RUNNABLE_AWS_SECRET_KEY" ]; then
  echo -e "${STYLE_BOLD}${COLOR_ERROR}Missing credentials.${STYLE_RESET}"
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
  REPO_DIR=$(echo "${REPO_ARRAY[index]}" | awk '{split($0,r,"/"); print r[2];}')
  REPO_FULL_NAME=$(echo "${REPO_ARRAY[index]}" | awk '{split($0,r,":"); print r[2];}')
  echo -e  "${STYLE_BOLD}${COLOR_STATUS}Cloning '$REPO_FULL_NAME' into './$REPO_DIR'...${STYLE_RESET}"
  pushd $TEMPDIR > /dev/null
  ssh-add -D > /dev/null 2>&1
  ssh-add "$TEMPKEYDIR"/"${KEY_ARRAY[index]}" > /dev/null 2>&1
  git clone -q "${REPO_ARRAY[index]}" "$REPO_DIR"
  # Enter the repository
  pushd $REPO_DIR > /dev/null
  git checkout -q "${COMMITISH_ARRAY[index]}"
  if [ "$RUNNABLE_COMMITISH" ]; then
    git checkout -q "${COMMITISH_ARRAY[index]}"
  fi
  # File the times in the file tree (for Docker ADD improvements)
  cp "$BUILDER_LIB_DIR"/fixFiletreeTimes.sh ./fixFiletreeTimes.sh
  chmod +x ./fixFiletreeTimes.sh
  # don't want anything but error messages out of this script
  ./fixFiletreeTimes.sh > /dev/null
  rm ./fixFiletreeTimes.sh
  # Leave repo folder
  popd > /dev/null
  # Leave temp folder
  popd > /dev/null
  echo ""
done

# S3 DOWNLOAD
if [ "$RUNNABLE_FILES" ]; then
  echo -e  "${STYLE_BOLD}${COLOR_STATUS}Downloading build files...${STYLE_RESET}"
  node downloadS3Files.js \
    --bucket "$RUNNABLE_FILES_BUCKET" \
    --files "$RUNNABLE_FILES" \
    --prefix "$RUNNABLE_PREFIX" \
    --dest "$TEMPDIR"
  echo ""
fi

# DOCKER BUILD
if [ "$RUNNABLE_DOCKER" ] && [ "$RUNNABLE_DOCKERTAG" ]; then
  echo -e  "${STYLE_BOLD}${COLOR_STATUS}Building box...${STYLE_RESET}"
  docker -H\="$RUNNABLE_DOCKER" build \
    -t "$RUNNABLE_DOCKERTAG" \
    $RUNNABLE_DOCKER_BUILDOPTIONS \
    "$TEMPDIR"
  echo ""
fi

echo -e  "${STYLE_BOLD}${COLOR_SUCCESS}Build completed successfully!${STYLE_RESET}"

IFS=$IFS_BAK
IFS_BAK=