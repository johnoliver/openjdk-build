/*
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

def unkeepAllBuildsOfType(buildName, build) {
    if (build != null) {
        if (build.displayName == buildName) {
            build.keepLog(false)
        }
        lastSuccessfullBuild(buildName, build.getPreviousBuild())
    }
}

def keepLastSuccessfulBuildOfType(buildName, build, found) {
    if (build != null) {
        if (displayName == buildName && build.result == 'SUCCESS') {
            if (found == false) {
                build.getRawBuild().keepLog(true)
                found = true
            } else {
                build.getRawBuild().keepLog(false)
            }
        }
        keepLastSuccessfulAllBuildsOfType(buildName, build.getPreviousBuild(), found)
    }
}

def setKeepFlagsForThisBuild(build, success) {
    // Currently disabled as this script runs in sandbox and cannot access build.getRawBuild()
    // Enable this if we want to allow this script to run outside a sandbox
    return

    build.getRawBuild().keepLog(true)
    lastBuild = build.getPreviousBuild()
    if (success) {
        //build successful so allow all other builds to be removed if needed
        unkeepAllBuildsOfType(build.displayName, lastBuild)
    } else {
        //build unsuccessful so keep last success and this one
        keepLastSuccessfulBuildOfType(build.displayName, lastBuild, false)
    }
}

currentBuild.displayName = "${JAVA_TO_BUILD}-${TARGET_OS}-${ARCHITECTURE}-${VARIANT}"
node(NODE_LABEL) {
    checkout scm

    success = false
    try {
        sh "./build-farm/make-adopt-build-farm.sh"
        archiveArtifacts artifacts: "workspace/target/*"
        success = true
    } catch (Exception e) {
        success = false
        currentBuild.result = 'FAILURE'
    } finally {
        setKeepFlagsForThisBuild(currentBuild, success)
    }
}

