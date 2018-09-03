#!/bin/bash

################################################################################
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
################################################################################

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck source=sbin/common/constants.sh
source "$SCRIPT_DIR/../../sbin/common/constants.sh"

export MACOSX_DEPLOYMENT_TARGET=10.8
export BUILD_ARGS="${BUILD_ARGS}"

XCODE_SWITCH_PATH="/";

if [ "${JAVA_TO_BUILD}" == "${JDK8_VERSION}" ]
then
  XCODE_SWITCH_PATH="/Applications/Xcode.app"
fi
sudo xcode-select --switch "${XCODE_SWITCH_PATH}"


if [ "${JAVA_TO_BUILD}" == "${JDK9_VERSION}" ] || [ "${JAVA_TO_BUILD}" == "${JDK10_VERSION}" ] || [ "${JAVA_TO_BUILD}" == "${JDK11_VERSION}" ]
then
    export PATH="/Users/jenkins/ccache-3.2.4:$PATH"
fi


if [ "${JAVA_TO_BUILD}" == "${JDK11_VERSION}" ]
then
    export JDK10_BOOT_DIR="$PWD/jdk-10.0.1+10"
    if [ ! -d "$JDK10_BOOT_DIR" ]; then
      wget -q -O - 'https://github.com/AdoptOpenJDK/openjdk10-releases/releases/download/201807101745/OpenJDK10_x64_Mac_201807101745.tar.gz' | tar xpfz -
    fi
    export JDK_BOOT_DIR=$JDK10_BOOT_DIR
fi