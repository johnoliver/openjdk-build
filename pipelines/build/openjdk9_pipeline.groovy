def buildConfigurations = [
        mac    : [os: 'mac', arch: 'x64', bootJDK: "${env.JDK8_BOOT_DIR}", aditionalNodeLabels: 'build'],
        linux  : [os: 'centos6', arch: 'x64', bootJDK: "${env.JDK8_BOOT_DIR}", aditionalNodeLabels: 'build'],

        // Currently we have to be quite specific about which windows to use as not all of them have freetype installed
        windows: [os: 'windows', arch: 'x64', bootJDK: "${env.JDK8_BOOT_DIR}", aditionalNodeLabels: 'build&&win2008']
]

if (osTarget != "all") {
    buildConfigurations = buildConfigurations
            .findAll { it.key == osTarget }
}

doBuild("jdk9", buildConfigurations)

///////////////////////////////////////////////////
//Do build is the same for all pipelines
//TODO: make it a shared library
def doBuild(javaToBuild, buildConfigurations) {
    if (osTarget != "all") {
        buildConfigurations = buildConfigurations
                .findAll { it.key == osTarget }
    }

    def buildJobs = []
    def jobs = [:]

    buildConfigurations.each { buildConfiguration ->
        def configuration = buildConfiguration.value

        def buildType = "${configuration.os}-${configuration.arch}"

        jobs[buildType] = {
            stage("build-${buildType}") {
                def buildJob = build job: "openjdk_build-refactor", parameters: [
                        string(name: 'JAVA_TO_BUILD', value: "${javaToBuild}"),
                        string(name: 'JDK_BOOT_DIR', value: "${configuration.bootJDK}"),
                        [$class: 'LabelParameterValue', name: 'NODE_LABEL', label: "${configuration.aditionalNodeLabels}&&${configuration.os}&&${configuration.arch}"]
                ]

                buildJobs.add([
                        job        : buildJob,
                        config     : configuration,
                        targetLabel: buildConfiguration.key
                ]);
            }

        }
    }
    parallel jobs

    node('centos6&&x64&&build') {
        buildJobs.each {
            buildJob ->
                if (buildJob.job.getResult() == 'SUCCESS') {
                    copyArtifacts(
                            projectName: 'openjdk_build-refactor',
                            selector: specific("${buildJob.job.getNumber()}"),
                            filter: 'workspace/target/*',
                            fingerprintArtifacts: true,
                            target: "target/${buildJob.targetLabel}/${buildJob.config.arch}/",
                            flatten: true)
                }
        }

        archiveArtifacts artifacts: 'target/*/*/*'
    }
}
