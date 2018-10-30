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



cd "$REPO"

if [ -d ".git" ];then
  git reset --hard
  git checkout master
  git merge --abort || true
  git am --abort || true
fi

cd "$SCRIPT_DIR"

chmod +x merge.sh

# Init new repo to head
./merge.sh -u -s "jdk8u181-b13"
git tag
./merge.sh -r -s "jdk8u181-b13"
git tag




################################################
## Build dev
## dev is HEAD track with our patches

cd "$REPO"
git branch dev
git am $PATCHES/company_name.patch
cd $SCRIPT_DIR
git tag
./merge.sh -s "jdk8u181-b13" -e "HEAD"
git tag
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
git checkout release
git am $PATCHES/company_name.patch
git am $PATCHES/ppc64le_1.patch
git am $PATCHES/ppc64le_2.patch


git tag -d "jdk8u181-b13" || true
git tag -f "jdk8u181-b13"

cd $SCRIPT_DIR
./merge.sh -s "jdk8u181-b13" -e "jdk8u192-b12" -b "release"
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

#./merge.sh -s "jdk8u192-b12" -e "HEAD"

#cd $REPO
#git push git@github.com:AdoptOpenJDK/openjdk-jdk8u-test.git
#git push git@github.com:AdoptOpenJDK/openjdk-jdk8u-test.git --tags


