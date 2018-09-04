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

export PATH="/opt/freeware/bin:/usr/local/bin:/opt/IBM/xlC/13.1.3/bin:/opt/IBM/xlc/13.1.3/bin:$PATH"
export CONFIGURE_ARGS_FOR_ANY_PLATFORM="${CONFIGURE_ARGS_FOR_ANY_PLATFORM} --with-memory-size=18000 --with-cups-include=/opt/freeware/include --with-extra-ldflags=-lpthread --with-extra-cflags=-lpthread --with-extra-cxxflags=-lpthread"
export BUILD_ARGS="${BUILD_ARGS} --skip-freetype"

if [ "${ARCHITECTURE}" == "x64" ] && [ "${VARIANT}" == "openj9" ];
then
  export CONFIGURE_ARGS_FOR_ANY_PLATFORM="${CONFIGURE_ARGS_FOR_ANY_PLATFORM} DF=/usr/sysv/bin/df"

  if [ "${JAVA_TO_BUILD}" == "${JDK8_VERSION}" ]
  then
    export CONFIGURE_ARGS_FOR_ANY_PLATFORM="${CONFIGURE_ARGS_FOR_ANY_PLATFORM} --with-freemarker-jar=/ramdisk0/build/workspace/openjdk8_openj9_build_ppc64_aix/freemarker-2.3.8/lib/freemarker.jar"
  elif [ "${JAVA_TO_BUILD}" == "${JDK9_VERSION}" ]
  then
    export CONFIGURE_ARGS_FOR_ANY_PLATFORM="${CONFIGURE_ARGS_FOR_ANY_PLATFORM} --with-freemarker-jar=/ramdisk0/build/workspace/openjdk9_openj9_build_ppc64_aix/freemarker-2.3.8/lib/freemarker.jar"
  elif [ "${JAVA_TO_BUILD}" == "${JDK10_VERSION}" ]
  then
    export CONFIGURE_ARGS_FOR_ANY_PLATFORM="${CONFIGURE_ARGS_FOR_ANY_PLATFORM} --with-freemarker-jar=/ramdisk0/build/workspace/openjdk10_openj9_build_ppc64_aix/freemarker-2.3.8/lib/freemarker.jar"
  elif [ "${JAVA_TO_BUILD}" == "${JDK11_VERSION}" ]
  then
    export CONFIGURE_ARGS_FOR_ANY_PLATFORM="${CONFIGURE_ARGS_FOR_ANY_PLATFORM} --with-freemarker-jar=/ramdisk0/build/workspace/openjdk10_openj9_build_ppc64_aix/freemarker-2.3.8/lib/freemarker.jar DF=/usr/sysv/bin/df"
  fi
fi

if [ "${JAVA_TO_BUILD}" == "${JDK11_VERSION}" ];
then
  export JDK10_BOOT_DIR="$PWD/jdk-10"
  if [ ! -d "$JDK10_BOOT_DIR/bin" ]; then
    mkdir -p "$JDK10_BOOT_DIR"
    wget -q -O - 'https://api.adoptopenjdk.net/v2/binary/releases/openjdk10?os=aix&release=latest' | tar xpzf - --strip-components=2 -C "$JDK10_BOOT_DIR"
  fi

  if [ "${VARIANT}" == "hotspot" ]; then
    export CONFIGURE_ARGS_FOR_ANY_PLATFORM="${CONFIGURE_ARGS_FOR_ANY_PLATFORM} DF=/usr/sysv/bin/df"
  fi

  export JDK_BOOT_DIR=$JDK10_BOOT_DIR

  export LANG=C
  export PATH=/opt/freeware/bin:$JAVA_HOME/bin:/usr/local/bin:/opt/IBM/xlC/13.1.3/bin:/opt/IBM/xlc/13.1.3/bin:$PATH
  export CONFIGURE_ARGS_FOR_ANY_PLATFORM="--disable-warnings-as-errors ${CONFIGURE_ARGS_FOR_ANY_PLATFORM}"
fi
