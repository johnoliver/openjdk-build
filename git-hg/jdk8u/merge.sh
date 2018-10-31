#!/usr/bin/env bash

set -exu

source constants.sh

tag="jdk8u172-b08"
workingBranch="master"
doReset="false"
doInit="false"
doTagging="false"

function initRepo() {
  rm -rf "$REPO"
  mkdir -p "$REPO"
  cd "$REPO"
  git clone $MIRROR/root/ .
  git checkout master
  git reset --hard "$tag"
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
    git tag -d $tag || true
  done
}

function inititialCheckin() {
  tag=$1
  cd "$REPO"
  if [ "$workingBranch" != "master" ]; then
    git branch -D "$workingBranch" || true
    git checkout --orphan "$workingBranch"
    git rm -rf .
  else
    git checkout master
  fi

  if [ "$tag" != "HEAD" ]; then
    git fetch root --no-tags +refs/tags/$tag:refs/tags/$tag-root
  else
    git fetch root --no-tags HEAD
  fi
  git branch
  git merge "$tag-root"

  if [ "$doTagging" == "true" ]; then
    git tag -d $tag || true
  fi

  for module in "${MODULES[@]}" ; do
      cd "$MIRROR/$module/";
      commitId=$(git rev-list -n 1  $tag)
      cd "$REPO"
      /usr/lib/git-core/git-subtree add --prefix=$module "$MIRROR/$module/" $tag
  done

  cd "$REPO"
  git tag | while read tag
  do
    git tag -d $tag || true
  done
}

function resetRepo() {
    rm -rf "$MODULE_MIRROR/root"
    mkdir -p "$MODULE_MIRROR/root"
    mkdir -p "$MODULE_MIRROR/root"
    cd "$MODULE_MIRROR/root"

    git init

    git remote add -f "upstream" "$MIRROR/root/"
    git merge $tag
    git tag -f "$tag"

    for module in "${MODULES[@]}" ; do
      rm -rf "$MODULE_MIRROR/$module"
      mkdir -p "$MODULE_MIRROR/$module"
      mkdir -p "$MODULE_MIRROR/$module"
      cd "$MODULE_MIRROR/$module"

      git init

      git remote add -f "upstream" "$MIRROR/$module/"
      git merge $tag

      git tag | while read tag
      do
        git tag -d $tag || true
      done

      git tag -f "$tag"
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


while getopts "iturT:b:" opt; do
    case "${opt}" in
        i)
            doInit="true"
            ;;
        t)
            doTagging="true"
            ;;
        u)
            updateMirrors
            exit
            ;;
        r)
            doReset="true"
            doInit="true"
            ;;
        T)
            tag=${OPTARG}
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
  inititialCheckin $tag
  exit
fi

echo "$tag" >> $WORKSPACE/mergedTags

cd "$MIRROR/root/";
commitId=$(git rev-list -n 1  $tag)

cd "$REPO"
git checkout $workingBranch

if [ "$doTagging" == "true" ]; then
  git tag -d $tag || true
fi

if [ "$tag" != "HEAD" ]; then
  git fetch --no-tags root +refs/tags/$tag:refs/tags/$tag-root
else
  git fetch --no-tags root HEAD
fi

set +e
git merge -q -m "Merge root at $tag" $commitId
returnCode=$?
set -e

if [[ "$returnCode" -ne "0" ]]; then
  if [ "$(git diff --name-only --diff-filter=U | wc -l)" == "1" ] && [ "$(git diff --name-only --diff-filter=U)" == "common/autoconf/generated-configure.sh" ];
  then
    fixAutoConfigure
  else
      echo "Conflicts"
      exit 1
  fi
fi

cd "$REPO"
for module in "${MODULES[@]}" ; do
    /usr/lib/git-core/git-subtree pull -q -m "Merge $module at $tag" --prefix=$module "$MIRROR/$module/" $tag
done

echo "Success $tag" >> $WORKSPACE/mergedTags

if [ "$doTagging" == "true" ]; then
  cd "$REPO"
  git tag  -d "$tag" || true
  git branch -D "$tag" || true
  git branch "$tag"
  git tag  -f "$tag"
fi

cd "$REPO"

git tag | grep ".*\-root" | while read tag
do
  git tag -d $tag || true
done

git prune
git gc