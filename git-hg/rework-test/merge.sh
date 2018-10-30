#!/usr/bin/env bash

set -exu

# Set up the workspace to work from
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
mkdir -p $SCRIPT_DIR/workspace
WORKSPACE=$SCRIPT_DIR/workspace

# REPO_LOCATION     - workspace/adoptopenjdk-clone/      - copy of upstream github repo where new commits will end up
# MIRROR            - workspace/openjdk-clean-mirror     - Unmodified clones of openjdk mercurial (basically a local cache)
# REWRITE_WORKSPACE - workspace/openjdk-rewritten-mirror - Workspace where mercurial is manipulated before being written into the upstream
#                   - workspace/bin                      - Helper third party programs


MIRROR="$WORKSPACE/openjdk-clean-mirror"
REWRITE_WORKSPACE="$WORKSPACE/openjdk-rewritten-mirror/"
REPO_LOCATION="$WORKSPACE/adoptopenjdk-clone/"

MODULE_MIRROR="$WORKSPACE/module-mirrors/"

mkdir -p "$MODULE_MIRROR"

# These the the modules in the mercurial forest that we'll have to iterate over
MODULES=(corba langtools jaxp jaxws nashorn jdk hotspot)
MODULES_WITH_ROOT=(root corba langtools jaxp jaxws nashorn jdk hotspot)

DO_TAGGING="false"

REPO="$WORKSPACE/test-repo/"


startTag="jdk8u172-b08"
endTag="jdk8u181-b13"
workingBranch="master"

function initRepo() {
  rm -rf "$REPO"
  mkdir -p "$REPO"
  cd "$REPO"
  git clone $MIRROR/root/ .
  git checkout master
  git reset --hard "$startTag"
  git remote add "root" "$MIRROR/root/"

  for module in "${MODULES[@]}" ; do
      cd "$MIRROR/$module/";
      git checkout master
      git reset --hard
      firstCommitId=$(git rev-list --max-parents=0 HEAD)
  done

  cd "$REPO"
  git tag | while read tag
  do
    git tag -d $tag;
  done
}

function canMergeTag() {
    tag=$1
    lastSuccessfulTag=$2

    canMerge="true"

    if [ "$tag" == "HEAD" ]; then
      echo "true"
      return
    fi


    cd "$REPO"
    if [ "$DO_TAGGING" == "true" ] && [ ! $(git tag -l "$tag") ]; then
        # tag already exists in repo
        canMerge="false"
    fi

    for module in "${MODULES_WITH_ROOT[@]}" ; do
        cd "$MIRROR/$module/";
        if [ ! $(git tag -l "$tag") ]; then
            canMerge="false"
        else
          tagCommitId=$(git rev-parse --verify $tag)
          lastTagCommitId=$(git rev-parse --verify $lastSuccessfulTag)

          git merge-base --is-ancestor $lastTagCommitId $tagCommitId
          if [ $? != 0 ]; then
              canMerge="false"
          fi
        fi
    done

    echo "$canMerge"
}

function inititialCheckin() {
  tag=$1
  cd "$REPO"
  if [ "$workingBranch" != "master" ]; then
    git checkout --orphan release
    git rm -rf .
  else
    git checkout master
  fi

  git fetch --tag root $tag
  git branch
  git merge "$tag"

  if [ "$DO_TAGGING" == "true" ]; then
    git tag -d $tag
  fi

  for module in "${MODULES[@]}" ; do
      cd "$MIRROR/$module/";
      commitId=$(git rev-list -n 1  $tag)
      /usr/lib/git-core/git-subtree add --prefix=$module "$MIRROR/$module/" $tag
  done

  git tag | while read tag
  do
    git tag -d $tag;
  done
}

function resetRepo() {
    rm -rf "$MODULE_MIRROR/root"
    mkdir -p "$MODULE_MIRROR/root"
    mkdir -p "$MODULE_MIRROR/root"
    cd "$MODULE_MIRROR/root"

    git init

    git remote add -f "upstream" "$MIRROR/root/"
    git merge $startTag
    git tag -f "$startTag"

    for module in "${MODULES[@]}" ; do
      rm -rf "$MODULE_MIRROR/$module"
      mkdir -p "$MODULE_MIRROR/$module"
      mkdir -p "$MODULE_MIRROR/$module"
      cd "$MODULE_MIRROR/$module"

      git init

      git remote add -f "upstream" "$MIRROR/$module/"
      git merge $startTag

      git tag | while read tag
      do
        git tag -d $tag;
      done

      git tag -f "$startTag"
    done
}


function updateRepo() {
  repoName=$1
  repoLocation=$2

  if [ ! -d "$MIRROR/$repoName/.git" ]; then
    rm -rf "$MIRROR/$repoName" || exit 1
    mkdir -p "$MIRROR/$repoName" || exit 1
    cd "$MIRROR/$repoName"
    git clone "hg::${repoLocation}" .
  fi

  cd "$MIRROR/$repoName"
  git fetch origin
  git pull origin
  git reset --hard origin/master
  git fetch --all

}

function updateMirrors() {
  mkdir -p "$MIRROR"
  cd "$MIRROR" || exit 1

  HG_REPO="https://hg.openjdk.java.net/jdk8u/jdk8u"

  updateRepo "root" "${HG_REPO}"

  for module in "${MODULES[@]}" ; do
      updateRepo "$module" "${HG_REPO}/$module"
  done
}

function fixAutoConfigure() {
    chmod +x ./common/autoconf/autogen.sh
    ./common/autoconf/autogen.sh
    git commit -a --no-edit
}

doReset="false"
doInit="false"

while getopts "iturs:e:b:" opt; do
    case "${opt}" in
        i)
            doInit="true"
            ;;
        t)
            DO_TAGGING="true"
            ;;
        u)
            updateMirrors
            exit
            ;;
        r)
            doReset="true"
            doInit="true"
            ;;
        s)
            startTag=${OPTARG}
            ;;
        e)
            endTag=${OPTARG}
            ;;
        b)
            workingBranch=${OPTARG}
            ;;
        *)
            usage
            exit
            ;;
    esac
done
shift $((OPTIND-1))


if [ "$doReset" == "true" ]; then
  initRepo
fi

if [ "$doInit" == "true" ]; then
  inititialCheckin $startTag
  exit
fi

export lastSuccessfulTag="$startTag"

for tag in $startTag $endTag
do
  cd "$MIRROR/root"
  failed="false"

    echo $tag
    canMerge=$(canMergeTag "$tag" "$lastSuccessfulTag")

    if [ "$canMerge" != "true" ]; then
      echo "Skipping $tag due to not being able to merge"
      continue
    fi

    cd "$REPO"

    echo "$tag" >> $WORKSPACE/mergedTags

    cd "$MIRROR/root/";
    commitId=$(git rev-list -n 1  $tag)

    cd "$REPO"
    git checkout $workingBranch

    if [ "$DO_TAGGING" == "true" ]; then
      git tag -d $tag || true
    fi
    git fetch -q root $tag

    set +e
    git merge -q -m "Merge root at $tag" $commitId

    if [[ "$?" -ne "0" ]]; then
      if [ "$(git diff --name-only --diff-filter=U | wc -l)" == "1" ] && [ "$(git diff --name-only --diff-filter=U)" == "common/autoconf/generated-configure.sh" ];
      then
        fixAutoConfigure
      else
          git reset --hard $lastSuccessfulTag
          failed="true"
          continue
      fi
    fi
    set -e

    for module in "${MODULES[@]}" ; do
        if [ "$failed" == "true" ]; then
          continue;
        fi

        cd "$REPO"

        set +e
        /usr/lib/git-core/git-subtree pull -q -m "Merge $module at $tag" --prefix=$module "$MIRROR/$module/" $tag

        if [[ "$?" -ne "0" ]]; then
            git reset --hard $lastSuccessfulTag
            failed="true"
        fi
        set -e
    done
    echo "Success $tag" >> $WORKSPACE/mergedTags

    lastSuccessfulTag="$tag"
    if [ "$DO_TAGGING" == "true" ]; then
      cd "$REPO"
      git tag  -d "$tag" || true
      git branch -D "$tag" || true
      git branch "$tag"
      git tag  -f "$tag"
    fi
done

cd "$REPO"
git prune
git gc