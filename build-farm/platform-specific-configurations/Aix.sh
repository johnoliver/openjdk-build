#!/bin/bash

export PATH="/opt/freeware/bin:/usr/local/bin:/opt/IBM/xlC/13.1.3/bin:/opt/IBM/xlc/13.1.3/bin:$PATH"
export CONFIGURE_ARGS_FOR_ANY_PLATFORM="${CONFIGURE_ARGS_FOR_ANY_PLATFORM} --with-memory-size=18000 --with-cups-include=/opt/freeware/include --with-extra-ldflags=-lpthread --with-extra-cflags=-lpthread --with-extra-cxxflags=-lpthread"
export BUILD_ARGS="${BUILD_ARGS} --skip-freetype"

if [ "${ARCHITECTURE}" == "x64" ] && [ "${VARIANT}" == "openj9" ]
then
  export CONFIGURE_ARGS_FOR_ANY_PLATFORM="${CONFIGURE_ARGS_FOR_ANY_PLATFORM} --with-freemarker-jar=/ramdisk0/build/workspace/openjdk9_openj9_build_ppc64_aix/freemarker-2.3.8/lib/freemarker.jar DF=/usr/sysv/bin/df"
fi