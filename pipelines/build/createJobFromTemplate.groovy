String buildFolder = "$JOB_FOLDER"

if (!binding.hasVariable('JDK_BOOT_VERSION')) JDK_BOOT_VERSION = ""
if (!binding.hasVariable('CONFIGURE_ARGS')) CONFIGURE_ARGS = ""
if (!binding.hasVariable('BUILD_ARGS')) BUILD_ARGS = ""
if (!binding.hasVariable('ADDITIONAL_FILE_NAME_TAG')) ADDITIONAL_FILE_NAME_TAG = ""

folder(buildFolder) {
    description 'Automatically generated build jobs.'
}

pipelineJob("$buildFolder/$JOB_NAME") {
    description('<h1>THIS IS AN AUTOMATICALLY GENERATED JOB DO NOT MODIFY, IT WILL BE OVERWRITTEN.</h1><p>This job is defined in createJobFromTemplate.dsl in the openjdk-build repo, if you wish to change it modify that</p>')
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url('https://github.com/johnoliver/openjdk-build.git')
                    }
                    branch('*/overhaul-build-scripts-6')
                    extensions {
                        cleanBeforeCheckout()
                    }
                }
            }
            scriptPath('pipelines/build/openjdk_build_pipeline.groovy')
            lightweight(true)
        }
    }
    properties {
        copyArtifactPermissionProperty {
            projectNames('*')
        }
    }
    logRotator {
        numToKeep(5)
    }
    parameters {
        stringParam('TAG', null, "git tag/branch/commit to bulid if not HEAD")
        stringParam('NODE_LABEL', "$NODE_LABEL")
        stringParam('JAVA_TO_BUILD', "$JAVA_TO_BUILD")
        stringParam('JDK_BOOT_VERSION', "${JDK_BOOT_VERSION}")
        stringParam('CONFIGURE_ARGS', "$CONFIGURE_ARGS", "Additional arguments to pass to ./configure")
        stringParam('BUILD_ARGS', "$BUILD_ARGS", "additional args to call makejdk-any-platform.sh with")
        stringParam('ARCHITECTURE', "$ARCHITECTURE")
        stringParam('VARIANT', "$VARIANT")
        stringParam('TARGET_OS', "$TARGET_OS")
        stringParam('ADDITIONAL_FILE_NAME_TAG', "$ADDITIONAL_FILE_NAME_TAG")
    }
}