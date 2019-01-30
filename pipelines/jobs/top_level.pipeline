import groovy.json.JsonOutput

folder("${buildFolder}")
folder("${buildFolder}/jobs")

pipelineJob("$buildFolder/$job") {
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url("${GIT_URL}")
                    }
                    branch("${BRANCH}")
                }
            }
            scriptPath(script)
        }
    }
    logRotator {
        numToKeep(5)
    }
    parameters {
        textParam('targetConfigurations', JsonOutput.prettyPrint(JsonOutput.toJson(targetConfigurations)))
        booleanParam('enableTests', false)
        booleanParam('publish', false)
        stringParam('releaseTag', "")
        stringParam('branch', "")
        stringParam('additionalConfigureArgs', "")
        stringParam('additionalBuildArgs', "")
        stringParam('additionalFileNameTag', "")
        booleanParam('cleanWorkspaceBeforeBuild', false)
        stringParam('adoptBuildNumber', "")
    }
}