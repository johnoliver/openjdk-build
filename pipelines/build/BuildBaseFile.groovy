import groovy.json.JsonSlurper

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

def buildConfiguration(javaToBuild, variant, configuration, releaseTag) {

    String buildTag = "build"

    if (configuration.os == "windows" && variant == "openj9") {
        buildTag = "buildj9"
    } else if (configuration.arch == "s390x" && variant == "openj9") {
        buildTag = "openj9"
    }

    def additionalNodeLabels
    if (configuration.containsKey("additionalNodeLabels")) {
        // hack as jenkins sandbox wont allow instanceof
        if ("java.util.LinkedHashMap" == configuration.additionalNodeLabels.getClass().getName()) {
            additionalNodeLabels = configuration.additionalNodeLabels.get(variant)
        } else {
            additionalNodeLabels = configuration.additionalNodeLabels
        }

        additionalNodeLabels = "${additionalNodeLabels}&&${buildTag}"
    } else {
        additionalNodeLabels = buildTag
    }

    List buildParams = [
            string(name: 'JAVA_TO_BUILD', value: "${javaToBuild}"),
            [$class: 'LabelParameterValue', name: 'NODE_LABEL', label: "${additionalNodeLabels}&&${configuration.os}&&${configuration.arch}"]
    ]

    if (configuration.containsKey('bootJDK')) buildParams += string(name: 'JDK_BOOT_VERSION', value: "${configuration.bootJDK}")
    if (configuration.containsKey('configureArgs')) buildParams += string(name: 'CONFIGURE_ARGS', value: "${configuration.configureArgs}")
    if (configuration.containsKey('buildArgs')) buildParams += string(name: 'BUILD_ARGS', value: "${configuration.buildArgs}")
    if (configuration.containsKey('additionalFileNameTag')) buildParams += string(name: 'ADDITIONAL_FILE_NAME_TAG', value: "${configuration.additionalFileNameTag}")

    if (releaseTag != null && releaseTag.length() > 0) {
        buildParams += string(name: 'TAG', value: "${releaseTag}")
    }

    buildParams += string(name: 'VARIANT', value: "${variant}")
    buildParams += string(name: 'ARCHITECTURE', value: "${configuration.arch}")
    buildParams += string(name: 'TARGET_OS', value: "${configuration.os}")

    return [
            javaVersion: javaToBuild,
            arch       : configuration.arch,
            os         : configuration.os,
            variant    : variant,
            parameters : buildParams,
            test       : configuration.test,
    ]
}

def getJobConfigurations(javaToBuild, buildConfigurations, String osTarget, String releaseTag) {
    def jobConfigurations = [:]

    new JsonSlurper()
            .parseText(osTarget)
            .each { target ->
        if (buildConfigurations.containsKey(target.key)) {
            def configuration = buildConfigurations.get(target.key)
            target.value.each { variant ->
                GString name = "${configuration.os}-${configuration.arch}-${variant}"
                if (configuration.containsKey('additionalFileNameTag')) {
                    name += "-${configuration.additionalFileNameTag}"
                }
                jobConfigurations[name] = buildConfiguration(javaToBuild, variant, configuration, releaseTag)
            }
        }
    }

    return jobConfigurations
}

static Integer getJavaVersionNumber(version) {
    // version should be something like "jdk8u"
    def matcher = (version =~ /(\d+)/)
    return Integer.parseInt(matcher[0][1])
}

static def determineTestJobName(config, testType) {

    def variant
    def number = getJavaVersionNumber(config.javaVersion)

    if (config.variant == "openj9") {
        variant = "j9"
    } else {
        variant = "hs"
    }

    def arch = config.arch
    if (arch == "x64") {
        arch = "x86-64"
    }

    def os = config.os
    if (os == "mac") {
        os = "macos"
    }

    return "openjdk${number}_${variant}_${testType}_${arch}_${os}"
}

static def determineReleaseRepoVersion(javaToBuild) {
    def number = getJavaVersionNumber(javaToBuild)

    return "jdk${number}"
}

def createJob(displayName, config) {
    def createJobName="create-${displayName}"
    def jobName="new-build-${displayName}";
    configuration.value.parameters += string(name: 'JOB_NAME', value: "${displayName}")
    create = build job: 'create-build-job', displayName: createJobName, parameters: config.parameters
    return create
}


def doBuild(String javaToBuild, buildConfigurations, String osTarget, String enableTestsArg, String publishArg, String releaseTag) {

    if (releaseTag == null || releaseTag == "false") {
        releaseTag = ""
    }

    def jobConfigurations = getJobConfigurations(javaToBuild, buildConfigurations, osTarget, releaseTag)
    def jobs = [:]
    def buildJobs = [:]

    def enableTests = enableTestsArg == "true"
    def publish = publishArg == "true"


    echo "Java: ${javaToBuild}"
    echo "OS: ${osTarget}"
    echo "Enable tests: ${enableTests}"
    echo "Publish: ${publish}"
    echo "ReleaseTag: ${releaseTag}"

    def downstreamJob = "openjdk_build"

    jobConfigurations.each { configuration ->
        jobs[configuration.key] = {
            catchError {
                def job
                def config = configuration.value


                stage(configuration.key) {
                    createJob(configuration.key, config);

                    //job = build job: "create-${displayName}", displayName: configuration.key, propagate: false, parameters: config.parameters
                    //buildJobs[configuration.key] = job
                }
            }
        }
    }

    parallel jobs

    if (publish) {
        def release = false
        def tag = javaToBuild
        if (releaseTag != null && releaseTag.length() > 0) {
            release = true
            tag = releaseTag
        }

        node("master") {
            stage("publish") {
                build job: 'refactor_openjdk_release_tool',
                        parameters: [string(name: 'RELEASE', value: "${release}"),
                                     string(name: 'TAG', value: tag),
                                     string(name: 'UPSTREAM_JOB_NAME', value: env.JOB_NAME),
                                     string(name: 'UPSTREAM_JOB_NUMBER', value: "${currentBuild.getNumber()}"),
                                     string(name: 'VERSION', value: determineReleaseRepoVersion(javaToBuild))]
            }
        }
    }
}

return this