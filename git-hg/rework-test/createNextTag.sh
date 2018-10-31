#!/bin/bash

set -eux

# Set up the workspace to work from
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
mkdir -p "$SCRIPT_DIR/workspace"
WORKSPACE="$SCRIPT_DIR/workspace"
MIRROR="$WORKSPACE/openjdk-clean-mirror"
REWRITE_WORKSPACE="$WORKSPACE/openjdk-rewritten-mirror/"
REPO_LOCATION="$WORKSPACE/adoptopenjdk-clone/"
REPO="$WORKSPACE/test-repo/"
PATCHES="$SCRIPT_DIR/patches/"
mkdir -p "$REPO"

cd "$SCRIPT_DIR"
chmod +x merge.sh

# Update mirrors
./merge.sh -u

cd "$REPO"
git reset --hard
git merge --abort || true
git am --abort || true
git checkout release
git reset --hard

TAG="jdk8u192-b12"
if [ "$#" -gt 0 ]; then
  TAG="$1"
fi

cd $SCRIPT_DIR
# move from jdk8u181-b13 to jdk8u192-b12
./merge.sh -s "jdk8u181-b13" -e "$TAG" -b "release"


