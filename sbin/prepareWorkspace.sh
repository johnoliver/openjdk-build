#!/usr/bin/env bash

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


# set -x # TODO remove once we've finished debugging
set -ex

source "$SCRIPT_DIR/common-functions.sh"

# i.e. Where we are
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# TODO refactor this for SRP
checkoutAndCloneOpenJDKGitRepo()
{

  cd "${BUILD_CONFIG[WORKSPACE_DIR]}/${BUILD_CONFIG[WORKING_DIR]}"

  # Check that we have a git repo of a valid openjdk version on our local file system
  if [ -d "${BUILD_CONFIG[OPENJDK_SOURCE_DIR]}/.git" ] && ( [ "${BUILD_CONFIG[OPENJDK_CORE_VERSION]}" == "jdk8" ] || [ "${BUILD_CONFIG[OPENJDK_CORE_VERSION]}" == "jdk9" ] || [ "${BUILD_CONFIG[OPENJDK_CORE_VERSION]}" == "jdk10" ]) ; then
    local openjdk_git_repo_owner=$(git --git-dir "${BUILD_CONFIG[OPENJDK_SOURCE_DIR]}/.git" remote -v | grep "${BUILD_CONFIG[OPENJDK_CORE_VERSION]}")

    # If the local copy of the git source repo is valid then we reset appropriately
    if [ "${openjdk_git_repo_owner}" ]; then
      cd "${BUILD_CONFIG[OPENJDK_SOURCE_DIR]}" || return
      echo "${info}Resetting the git openjdk source repository at $PWD in 10 seconds...${normal}"
      sleep 10
      echo "${git}Pulling latest changes from git openjdk source repository${normal}"

      showShallowCloningMessage "fetch"
      git fetch --all ${BUILD_CONFIG[SHALLOW_CLONE_OPTION]}
      git reset --hard origin/${BUILD_CONFIG[BRANCH]}
      if [ ! -z "${BUILD_CONFIG[TAG]}" ]; then
        git checkout "${BUILD_CONFIG[TAG]}"
      fi
      git clean -fdx
    else
      echo "Incorrect Source Code for ${BUILD_CONFIG[OPENJDK_FOREST_NAME]}.  This is an error, please check what is in $PWD and manually remove, exiting..."
      exit 1
    fi
  elif [ ! -d "${BUILD_CONFIG[OPENJDK_SOURCE_DIR]}/.git" ] ; then
    # If it doesn't exist, clone it
    echo "${info}Didn't find any existing openjdk repository at $(pwd)/${BUILD_CONFIG[WORKING_DIR]} so cloning the source to openjdk${normal}"
    cloneOpenJDKGitRepo
  fi

  cd "${BUILD_CONFIG[WORKSPACE_DIR]}"
}

cloneOpenJDKGitRepo()
{
  cd ${BUILD_CONFIG[WORKSPACE_DIR]}
  echo "${git}"
  local git_remote_repo_address;
  if [[ "${BUILD_CONFIG[USE_SSH]}" == "true" ]] ; then
     git_remote_repo_address="git@github.com:${BUILD_CONFIG[REPOSITORY]}.git"
  else
     git_remote_repo_address="https://github.com/${BUILD_CONFIG[REPOSITORY]}.git"
  fi

  showShallowCloningMessage "cloning"
  local git_clone_arguments=(${BUILD_CONFIG[SHALLOW_CLONE_OPTION]} '-b' "${BUILD_CONFIG[BRANCH]}" "$git_remote_repo_address" "${BUILD_CONFIG[WORKING_DIR]}/${BUILD_CONFIG[OPENJDK_SOURCE_DIR]}")

  echo "git clone ${git_clone_arguments[*]}"
  git clone "${git_clone_arguments[@]}"
  if [ ! -z "${BUILD_CONFIG[TAG]}" ]; then
    cd "${BUILD_CONFIG[WORKING_DIR]}/${BUILD_CONFIG[OPENJDK_SOURCE_DIR]}" || exit 1
    git checkout "${BUILD_CONFIG[TAG]}"
  fi

  # TODO extract this to its own function
  # Building OpenJDK with OpenJ9 must run get_source.sh to clone openj9 and openj9-omr repositories
  if [ "${BUILD_CONFIG[BUILD_VARIANT]}" == "openj9" ]; then
    cd "${BUILD_CONFIG[WORKING_DIR]}/${BUILD_CONFIG[OPENJDK_SOURCE_DIR]}" || return
    bash get_source.sh
  fi
  cd ${BUILD_CONFIG[WORKSPACE_DIR]}
}

showShallowCloningMessage()
{
    mode=$1
    if [[ "${BUILD_CONFIG[SHALLOW_CLONE_OPTION]}" == "" ]]; then
        echo "${info}Git repo ${mode} mode: deep (preserves commit history)${normal}"
    else
        echo "${info}Git repo ${mode} mode: shallow (DOES NOT contain commit history)${normal}"
    fi
}

##################################################################

function configureWorkspace() {
  time (
    checkoutAndCloneOpenJDKGitRepo
    downloadingRequiredDependencies
  )
}

