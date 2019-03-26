package common

def builder;
node("master") {
    checkout scm
    load "pipelines/build/common/import_lib.groovy"
    builder = load "pipelines/build/common/openjdk_build_pipeline.groovy"
}

builder.build(BUILD_CONFIGURATION)
