#!/bin/bash
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

################################################################################
# mirrorMercurialIntoGit
#
# Local setup of the Git clone of a OpenJDK mercurial repository
#
# Initial repo will be pushed to git@github.com:AdoptOpenJDK/openjdk-$GITHUB_REPO.git
#
# TODO Make the location of the git push a parameter
#
################################################################################

set -euo pipefail

echo "Import common functionality"
# shellcheck disable=SC1091
source import-common.sh

# Make sure we're in a valid dir as a workspace
[ -z "$WORKSPACE" ] || WORKSPACE=$PWD
echo "You are in $WORKSPACE"

# TODO generalise this for the non adopt build farm case
function checkArgs() {
  if [ "$1" -lt 1 ]; then
     echo Usage: "$0" '[jdk-updates/jdk10u|jdk/jdk] (branch)'
     echo "Hg Repo supplied should match a repository in http://hg.openjdk.java.net/"
     echo "For example, to get the latest jdk development repo:"
     echo "$0 jdk/jdk"
     echo "For example, to get the raw-string-literals branch from the amber repo:"
     echo "e.g. $0 amber/jdk raw-string-literals"
     exit 1
  fi
}

# Read in the mandatory Mercurial repo, e.g. jdk-updates/jdk10u
# Default to a master branch if one is not given
HG_REPO=$1
GITHUB_REPO=$(echo "$HG_REPO" | cut -d/ -f2)
BRANCH=${2:-master}

function cloneGitHubRepo() {
  # If we don't have a $GITHUB_REPO locally then clone it from AdoptOpenJDK/openjdk-$GITHUB_REPO.git
  if [ ! -d "$GITHUB_REPO" ] ; then
    git clone git@github.com:AdoptOpenJDK/openjdk-"$GITHUB_REPO".git "$GITHUB_REPO" || exit 1
  fi
}

function addMercurialUpstream() {
  cd "$GITHUB_REPO" || exit 1

  git fetch origin
  if ! git checkout "$BRANCH" ; then
    git checkout -b "$BRANCH" || exit 1
  else
    git reset --hard origin/"$BRANCH" || echo "Not resetting as no upstream exists"
  fi

  # shellcheck disable=SC2143
  if [ -z "$(git remote -v | grep 'hg')" ] ; then
    echo "Initial setup of hg::http://hg.openjdk.java.net/$HG_REPO"
    git remote add hg hg::http://hg.openjdk.java.net/"$HG_REPO"
  fi
}

function performMergeFromMercurialIntoGit() {
  git fetch hg
  git merge hg/"$BRANCH" -m "Merge $BRANCH" || (echo "The automatic update failed, time for manual intervention!" && exit 1)
  git gc --auto
  git push origin "$BRANCH" --tags || exit 1
}

# Merge master into dev as we build off dev at the AdoptOpenJDK Build farm
# dev contains patches that AdoptOpenJDK has beyond upstream OpenJDK
function performMergeIntoDevFromMaster() {
  git checkout dev || git checkout -b dev
  git rebase master || exit 1
  git push origin dev || exit 1
}

# TODO Need to cover always merging mercurial master into our GitHub dev branch
checkArgs $#
#checkGitVersion
installGitRemoteHg
cloneGitHubRepo
addMercurialUpstream
performMergeFromMercurialIntoGit
performMergeIntoDevFromMaster