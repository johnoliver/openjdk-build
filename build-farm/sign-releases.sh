#!/bin/bash

BUILD_ARGS=${BUILD_ARGS:-""}
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ "${OPERATING_SYSTEM}" == "mac" ] ; then
  EXTENSION="tar.gz"
elif [ "${OPERATING_SYSTEM}" == "windows" ] ; then
  EXTENSION="zip"
else
  exit 0
fi

ls -alh

for file in $(ls "./OpenJDK*.${EXTENSION}");
do
  sha256sum "$file" > $file.sha256.txt;

  echo "${SCRIPT_DIR}/../sign.sh ${BUILD_ARGS} ${file}"
  bash "${SCRIPT_DIR}/../sign.sh" ${BUILD_ARGS} "${file}"
done