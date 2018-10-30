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
if [ -d ".git" ];then
  git reset --hard
  git checkout master
  git merge --abort || true
  git am --abort || true
fi

# Update dev branch
cd "$REPO"
git checkout dev
cd $SCRIPT_DIR
./merge.sh -s "jdk8u181-b13" -e "HEAD" -b "dev"

# Update master branch
cd "$REPO"
git checkout master
cd $SCRIPT_DIR
./merge.sh -s "jdk8u181-b13" -e "HEAD" -b "master"


