# Repository for code and instructions for building OpenJDK

[![Build Status](https://travis-ci.org/AdoptOpenJDK/openjdk-build.svg?branch=master)](https://travis-ci.org/AdoptOpenJDK/openjdk-build) [![Slack](https://slackin-jmnmplfpdu.now.sh/badge.svg)](https://slackin-jmnmplfpdu.now.sh/)

AdoptOpenJDK makes use of these scripts to build binaries on the build farm at 
http://ci.adoptopenjdk.net, which produces OpenJDK binaries for consumption via 
https://www.adoptopenjdk.net and https://api.adoptopenjdk.net.

## TLDR I want to build a JDK NOW!

##### Build jdk natively on your system

```
./makejdk-any-platform.sh <jdk8u|jdk9|jdk10>
i.e:
./makejdk-any-platform.sh jdk8u
```

##### Build jdk inside a docker container
```
./makejdk-any-platform.sh --docker jdk8u
```
If you need sudo to run docker on your system.
```
./makejdk-any-platform.sh --sudo --docker jdk8u
```

## Build
The build has 2 modes, native and docker.

### Native 
Native builds run on whatever platform the script is invoked on, i.e 
if you invoke a native build on MacOS it will build a JDK for MacOS.

### Docker
This runs a build inside a docker container. Currently this will always 
build a linux JDK.

## Repository contents

This repository contains several useful scripts in order to build OpenJDK 
personally or at build farm scale.

1. The `build-farm` folder contains shell scripts for multi configuration Jenkins 
build jobs used for building Adopt OpenJDK binaries.  TODO This may get removed.
2. The `docker` folder contains DockerFiles which can be used as part of building 
OpenJDK inside a Docker container.
3. The `git-hg` folder contains scripts to clone an OpenJDK mercurial forest into 
a GitHub repo ()and regularly update it).
4. The `images` folder contains diagrams to aid understanding.
5. The `mercurial-tags/java-tool` folder contains scripts for TODO.
6. The `pipelines` folder contains the Groovy pipeline scripts for Jenkins 
(e.g. build | test | checksum | release).
7. The `sbin` folder contains the scripts that actually build (AdoptOpenJDK). 
`build.sh` is the entry point which can be used stand alone but is typically 
called by the `native-build.sh` or `docker-build.sh` scripts (which themselves
are typically called by `makejdk-any-platform.sh`).
8. The `security` folder contains a script and `cacerts` file that is bundled 
with the JDK and used when building OpenJDK: the `cacerts` file is an important 
file that's used to enable SSL connections.

## The makejdk-any-platform.sh script

`makejdk-any-platform.sh` is the entry point for building (Adopt) OpenJDK binaries. 
Building natively or in a docker container are both supported. This script (and 
its supporting scripts) have defaults, but you can override these as needed.
The scripts will auto detect the platform and architecture it is running on and 
configure the OpenJDK build accordingly.  The supporting scripts will also 
download and locally install any required dependencies for the OpenJDK build, 
e.g. The ALSA sound and Freetype font libraries.

Many of the configuration options are passed through to the `configure` and
`make` commands that OpenJDK uses to build binaries.  Please see the appropriate 
_README-builds.html_ file for the OpenJDK source repository that you are building. 

**NOTE:** Usage can be found via `makejdk-any-platform.sh --help`. Here is the 
man page re-formatted for convenience.

```
USAGE

./makejdk-any-platform [options] version

Please visit https://www.adoptopenjdk.net for further support.

VERSIONS

jdk8u - Build Java 8, defaults to https://github.com/AdoptOpenJDK/openjdk-jdk8u
jdk9 - Build Java 9, defaults to https://github.com/AdoptOpenJDK/openjdk-jdk9
jdk10 - Build Java 10, defaults to https://github.com/AdoptOpenJDK/openjdk-jdk10
jfx - Build OpenJFX, defaults to https://github.com/AdoptOpenJDK/openjdk-jfx
amber - Build Project Amber, defaults to https://github.com/AdoptOpenJDK/openjdk-amber

OPTIONS

-b, --branch <branch>
specify a custom branch to build from, e.g. dev.
For reference, AdoptOpenJDK GitHub source repos default to the dev
branch which may contain a very small diff set to the master branch
(which is a clone from the OpenJDK mercurial forest).

-B, --build-number <build_number>
specify the OpenJDK build number to build from, e.g. b12.
For reference, OpenJDK version numbers look like 1.8.0_162-b12 (for Java 8) or
9.0.4+11 (for Java 9+) with the build number being the suffix at the end.

-c, --clean-docker-build
removes the existing docker container and persistent volume before starting
a new docker based build.

-C, --configure-args <args>
specify any custom user configuration arguments.

-d, --destination <path>
specify the location for the built binary, e.g. /path/.
This is typically used in conjunction with -T to create a custom path
/ file name for the resulting binary.

-D, --docker
build OpenJDK in a docker container.

--disable-shallow-git-clone
disable the default fB--depth=1 shallow cloning of git repo(s).

-f, --freetype-dir
specify the location of an existing FreeType library.
This is typically used in conjunction with -F.

-F, --skip-freetype
skip building Freetype automatically.
This is typically used in conjunction with -f.

-i, --ignore-container
ignore the existing docker container if you have one already.

 -J, --jdk-boot-dir <jdk_boot_dir>
specify the JDK boot dir.
For reference, OpenJDK needs the previous version of a JDK in order to build
itself. You should select the path to a JDK install that is N-1 versions below
the one you are trying to build.

-k, --keep
if using docker, keep the container after the build.

-n, --no-colour
disable colour output.

-p, --processors <args>
specify the number of processors to use for the docker build.

-r, --repository <repository>
specify the repository to clone OpenJDK source from,
e.g. https://github.com/karianna/openjdk-jdk8u.

-s, --source <path>
specify the location to clone the OpenJDK source (and dependencies) to.

-S, --ssh
use ssh when cloning git.

--sign
sign the OpenJDK binary that you build.

--sudo
run the docker container as root.

-t, --tag <tag>
specify the repository tag that you want to build OpenJDK from.

-T, --target-file-name <file_name>
specify the final name of the OpenJDK binary.
This is typically used in conjunction with -D to create a custom file
name for the resulting binary.

-u, --update-version <update_version>
specify the update version to build OpenJDK from, e.g. 162.
For reference, OpenJDK version numbers look like 1.8.0_162-b12 (for Java 8) or
9.0.4+11 (for Java 9+) with the update number being the number after the '_'
(162) or the 3rd position in the semVer version string (4).
This is typically used in conjunction with -b.

-v, --build-variant <variant_name>
specify a OpenJDK build variant, e.g. openj9.
For reference, the default variant is hotspot and does not need to be specified.

-V, --jvm-variant <jvm_variant>
specify the JVM variant (server or client), defaults to server.

Example usage:

./makejdk-any-platform --docker jdk8u
./makejdk-any-platform -T MyOpenJDK10.tar.gz jdk10

```

### Script Relationships

![Build Variant Workflow](images/AdoptOpenJDK_Build_Script_Relationships.png)

The main script to build OpenJDK is `makejdk-any-platform.sh`, which itself uses 
and/or calls `configureBuild.sh`, `docker-build.sh` and/or `native-build.sh`. 

The structure of a build is:
 
 1. Configuration phase determines what the configuration of the build is based on your current
platform and and optional arguments provided
 1. Configuration is written out to `built_config.cfg`
 1. Build is kicked off by either creating a docker container or running the native build script
 1. Build reads in configuration from `built_config.cfg`
 1. Downloads source, dependencies and prepares build workspace
 1. Configure and invoke OpenJDK build via `make`
 1. Package up built artifacts
 
- Configuration phase is primarily performed by `configureBuild.sh` and `makejdk-any-platform.sh`.
- If a docker container is required it is built by `docker-build.sh`.
- In the build phase `sbin/build.sh` is invoked either natively or inside the docker container.
`sbin/build.sh` invokes `sbin/prepareWorkspace.sh` to download dependencies, source and perform 
general preparation.
- Rest of the build and packaging is then handled from `sbin/build.sh` 
 
## Building OpenJDK

### Building on the Build Farm

In order to build an OpenJDK variant on the build farm you need to follow the 
[Adding-a-new-build-variant](https://github.com/AdoptOpenJDK/TSC/wiki/Adding-a-new-build-variant) 
instructions.  The configuration options are often set in the Jenkins job and 
passed into `makejdk-any-platform.sh` script.

Note that the build nodes (list of hosts on the LH side) also have configuration 
where things like the BOOT_JDK environment variable is set.

### Building via Docker in your local environment

The simplest way to build OpenJDK using these scripts is to run `makejdk-any-platform.sh` 
and have your user be in the Docker group on the machine (or use the `--sudo` 
option to prefix all of your Docker commands with `sudo`). This script will create 
a Docker container that will be configured with all of the required dependencies 
and a base operating system in order to build OpenJDK.

Make sure you have started your Docker Daemon first!  For help with getting 
docker follow the instructions [here](https://docs.docker.com/engine/installation/). 
Once you have Docker started you can then use the script below to build OpenJDK.

Example Usage (TODO Add example of openj9):

`./makejdk-any-platform.sh --docker --sudo jdk8u`

#### Configuring Docker for non sudo use

To use the Docker commands without using the `--sudo` option, you will need to be 
in the Docker group which can be achieved with the following three commands 
(performed as `root`)

1. `sudo groupadd docker`: creates the Docker group if it doesn't already exist
2. `sudo gpasswd -a yourusernamehere docker`: adds a user to the Docker group
3. `sudo service docker restart`: restarts the Docker service so the above changes can take effect

### Building natively in your local environment

Please note that your build host will need to have certain pre-requisites met.  
We provide Ansible scripts in the 
[openjdk-infrastructure](https://www.github.com/AdoptOpenJDK/openjdk-infrastructure) 
project for setting these pre-requisites.

Example Usage (TODO Add example of openj9):

`./makejdk-any-platform.sh -s /home/openjdk10/src -d /home/openjdk/target -T MyOpenJDK10.tar.gz jdk10`

This would clone OpenJDK source from _https://github.com/AdoptOpenJDK/openjdk-jdk10_ 
to `/home/openjdk10/src`, configure the build with sensible defaults according 
to your local platform and then build (Adopt) OpenJDK and place the result in 
`/home/openjdk/target/MyOpenJDK10.tar.gz`.

### Building OpenJDK from a non Adopt source

These scripts default to using AdoptOpenJDK as the OpenJDK source repo to build 
from, but you can override this with the `-r` flag.
