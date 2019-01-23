/*
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/


def getJavaVersionNumber(version) {
    // version should be something like "jdk8u"
    def matcher = (version =~ /(\d+)/)
    return Integer.parseInt(matcher[0][1])
}

def parseVersion(version) {

    //Regexes based on those in http://openjdk.java.net/jeps/223
    // Technically the standard supports an arbitrary number of numbers, we will support 3 for now
    final vnumRegex = "(?<major>[0-9]+)(\\.(?<minor>[0-9]+))?(\\.(?<security>[0-9]+))?";
    final pre = "(?<pre>[a-zA-Z0-9]+)";
    final build = "(?<build>[0-9]+)";
    final opt = "(?<opt>[-a-zA-Z0-9\\.]+)";

    final version223Regexs = [
            "(?<version>${vnumRegex}(\\-${pre})?\\+${build}(\\-${opt})?)",
            "(?<version>${vnumRegex}\\-${pre}(\\-${opt})?)",
            "(?<version>${vnumRegex}(\\+\\-${opt})?)"
    ];

    final pre223regex = "jdk(?<version>(?<major>[0-8]+)(u(?<update>[0-9]+))?(-b(?<build>[0-9]+))(_(?<opt>[-a-zA-Z0-9\\.]+))?)";
    final matched = version =~ /${pre223regex}/

    echo "matching: " + version
    if (matched.matches()) {
        return [
                major   : matched.group('major'),
                minor   : matched.group('minor'),
                security: matched.group('security'),
                pre     : matched.group('pre'),
                build   : matched.group('build'),
                opt     : matched.group('opt'),
                version : matched.group('version')

        ]
    } else {
        /*
        version223Regexs
                .map { regex ->
            final matched = version =~ /${pre223regex}/
            if (matched.matches()) {

            }
        }*/
        return [];
    }

}

return this
