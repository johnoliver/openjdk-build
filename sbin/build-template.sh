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

################################################################################
#
# build-template.sh
#
# Writes the configure configuration to disk (config.status) for reuse
#
################################################################################

set +e

alreadyConfigured=$(/usr/bin/find . -name "config.status")

if [[ ! -z "$alreadyConfigured" ]] ; then
  echo "Not reconfiguring due to the presence of config.status"
else
  #Templated var that, gets replaced by build.sh
  # shellcheck disable=SC1073,SC1054,SC1083
  {configureArg}

  exitCode=$?
  if [ "${exitCode}" -ne 0 ]; then
    exit 2;
  fi
fi

#Templated var that, gets replaced by build.sh
{makeCommandArg}

exitCode=$?
# shellcheck disable=SC2181
if [ "${exitCode}" -ne 0 ]; then
   exit 3;
fi
