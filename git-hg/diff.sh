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
# diff
#
# For finding the diff between an AdoptOpenJDK Git repo and the OpenJDK Mercurial
# Repo for Java versions <= jdk9u
#
# 1. Clones the AdoptOpenJDK Git repo for a particular version
# 2. Clones the OpenJDK Mercurial repo for that same version
# 3. Runs a diff between the two
#
################################################################################

set -euo

function checkArgs() {
  if [ $# -lt 2 ]; then
     echo Usage: "$0" '[AdoptOpenJDK Git Repo Version] [OpenJDK Mercurial Root Forest Version]'
     echo ""
     echo "e.g. ./diff.sh jdk8u jdk8u"
     echo ""
     exit 1
  fi
}

checkArgs $@

git_repo_version=$1
hg_root_forest=${2:-${1}}                  # for backwards compatibility
hg_repo_version=${3:-${hg_root_forest}}    # for backwards compatibility

function cleanUp() {
  rm -rf openjdk-git openjdk-hg
}

function cloneRepos() {
  echo "AdoptOpenJDK Git Repo Version: ${git_repo_version}"
  echo "OpenJDK Mercurial Repo Version: ${hg_root_forest}/${hg_repo_version}"

  git clone -b master "https://github.com/AdoptOpenJDK/openjdk-${git_repo_version}.git" openjdk-git || exit 1
  hg clone "http://hg.openjdk.java.net/${hg_root_forest}/${hg_repo_version}" openjdk-hg || exit 1
}

function updateMercurialClone() {
  cd openjdk-hg || exit 1

  chmod u+x get_source.sh
  ./get_source.sh

  cd - || exit 1
}

function runDiff() {

  local ignoreArgs="-x '.git' -x '.hg' -x '.hgtags' -x '.hgignore' -x 'get_source.sh' -x 'README.md'"

  diffNum=$(diff -rq openjdk-git openjdk-hg $ignoreArgs | wc -l)

  if [ "$diffNum" -gt 0 ]; then
    echo "ERROR - THE DIFF HAS DETECTED UNKNOWN FILES"
    diff -rq openjdk-git openjdk-hg $ignoreArgs | grep 'Only in' || exit 1
    exit 1
  fi
}

function checkTags() {

  cd openjdk-git || exit 1
  gitTag=$(git describe --abbrev=0 --tags) || exit 1
  cd - || exit 1

  cd openjdk-hg || exit 1
  hgTag=$(hg log -r "." --template "{latesttag}\n") || exit 1
  cd - || exit 1

  if [ "$gitTag" == "$hgTag" ]; then
    echo "Tags are in sync"
  else
    echo "ERROR - THE TAGS ARE NOT IN SYNC"
    exit 1
  fi
}

cleanUp
cloneRepos
updateMercurialClone
runDiff
checkTags
