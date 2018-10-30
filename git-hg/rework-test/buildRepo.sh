#!/bin/bash

##cd git-hg
##bash -x ./mercurialToGitWithSubModules.sh http://hg.openjdk.java.net/jdk8u/jdk8u jdk8u git@github.com:AdoptOpenJDK openjdk-jdk8u-test

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



cd "$REPO"

git reset --hard
git checkout master
git merge --abort || true
git am --abort || true

cd "$SCRIPT_DIR"

chmod +x merge.sh

## Init new repo to head
#./merge.sh -u -s "jdk8u181-b13"
#./merge.sh -r -s "jdk8u181-b13"
#
#
#
#
#################################################
### Build dev
### dev is HEAD track with our patches
#
cd "$REPO"
#git branch dev
git am $PATCHES/1.patch
cd $SCRIPT_DIR
./merge.sh -s "jdk8u181-b13" -e "HEAD"
################################################



################################################
## Build release
## release moves from tag to tag with our patches
cd "$SCRIPT_DIR"

./merge.sh -t -i -s "jdk8u144-b34" -b "release"
./merge.sh -t -s "jdk8u144-b34" -e "jdk8u162-b12" -b "release"
./merge.sh -t -s "jdk8u162-b12" -e "jdk8u172-b11" -b "release"
./merge.sh -t -s "jdk8u172-b11" -e "jdk8u181-b13" -b "release"

cd $REPO
git am $PATCHES/1.patch
git am $PATCHES/2.patch
git am $PATCHES/3.patch
cd $SCRIPT_DIR
./merge.sh -s "jdk8u181-b13" -e "jdk8u192-b12"
################################################



#./merge.sh -u -s "jdk8u144-b34"
#./merge.sh -r -s "jdk8u144-b34"
#./merge.sh -s "jdk8u144-b34" -e "jdk8u162-b12"
#./merge.sh -s "jdk8u162-b12" -e "jdk8u172-b11"
#./merge.sh -s "jdk8u172-b11" -e "jdk8u181-b13"

#cd $REPO
#git checkout master
#git log
#git am  $PATCHES/1.patch
#git am  $PATCHES/2.patch
#git am  $PATCHES/3.patch

#cd $SCRIPT_DIR

#./merge.sh -s "jdk8u181-b13" -e "jdk8u192-b12"

./merge.sh -s "jdk8u192-b12" -e "HEAD"

#cd $REPO
#git push git@github.com:AdoptOpenJDK/openjdk-jdk8u-test.git
#git push git@github.com:AdoptOpenJDK/openjdk-jdk8u-test.git --tags


