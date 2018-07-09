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

def buildConfigurations = [
        x64Mac    : [
                os                  : 'mac',
                arch                : 'x64',
                additionalNodeLabels: 'build-macstadium-macos1010-1',
                test                : ['openjdktest', 'systemtest']
        ],

        x64Linux  : [
                os                 : 'linux',
                arch               : 'x64',
                additionalNodeLabels: 'centos6',
                test                : ['openjdktest', 'systemtest', 'perftest', 'externaltest']
        ],

        // Currently we have to be quite specific about which windows to use as not all of them have freetype installed
        x64Windows: [
                os                 : 'windows',
                arch               : 'x64',
                additionalNodeLabels: [
                        hotspot: 'win2008',
                        openj9:  'win2012'
                ],
                test                : ['openjdktest']
        ],

        ppc64Aix    : [
                os                 : 'aix',
                arch               : 'ppc64',
                test               : false
        ],

        s390xLinux    : [
                os                 : 'linux',
                arch               : 's390x',
                additionalNodeLabels: 'ubuntu',
                test                : ['openjdktest', 'systemtest']
        ],

        ppc64leLinux    : [
                os                 : 'linux',
                arch               : 'ppc64le',
                additionalNodeLabels: 'centos7',
                test                : ['openjdktest', 'systemtest']
        ],

        arm32Linux    : [
                os                 : 'linux',
                arch               : 'arm',
                test                : ['openjdktest']
        ],

        "LinuxXL"    : [
                os                  : 'linux',
                additionalNodeLabels: 'centos6',
                arch                : 'x64',
                test                : false,
                configureArgs       : '--with-noncompressedrefs'
        ],
]

def javaToBuild = "jdk8u"

node ("master") {
    checkout scm
    def buildFile = load "${WORKSPACE}/pipelines/build/BuildBaseFile.groovy"
    buildFile.doBuild(javaToBuild, buildConfigurations, osTarget, enableTests, publish)
}

