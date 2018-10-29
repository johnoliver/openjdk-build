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


REPO="$WORKSPACE/test-repo/"


startTag="jdk8u172-b08"
endTag="jdk8u181-b13"



#startTag="jdk8u192-b02" #possibly jdk8u181-b13
#endTag="jdk8u202-b01"


function initRepo() {
  rm -rf "$REPO"
  mkdir -p "$REPO"
  cd "$REPO"
  git clone $MIRROR/root/ .
  git checkout master
  git reset --hard "$startTag"
  git remote add "root" "$MIRROR/root/"
#  git fetch root $startTag
  #git merge root $startTag
  #git reset --hard FETCH_HEAD

  for module in "${MODULES[@]}" ; do
      cd "$MIRROR/$module/";
      git checkout master
      git reset --hard
      firstCommitId=$(git rev-list --max-parents=0 HEAD)

      cd "$REPO"
      #git remote add -f "$module-repo" "$MIRROR/$module/"
      #git fetch "$MIRROR/$module/"
  done

  git tag | while read tag
  do
    git tag -d $tag;
  done
}

function canMergeTag() {
    tag=$1
    lastSuccessfulTag=$2

    cd "$REPO"

    present="true"

    cd "$MIRROR/root/";
    if [ ! $(git tag -l "$tag") ]; then
        present="false"
    else
        tagCommitId=$(git rev-parse --verify $tag)
        lastTagCommitId=$(git rev-parse --verify $lastSuccessfulTag)

        git merge-base --is-ancestor $lastTagCommitId $tagCommitId
        if [ $? != 0 ]; then
            present="false"
        fi
    fi

    for module in "${MODULES[@]}" ; do
        cd "$MIRROR/$module/";
        if [ ! $(git tag -l "$tag") ]; then
            present="false"
        else
          tagCommitId=$(git rev-parse --verify $tag)
          lastTagCommitId=$(git rev-parse --verify $lastSuccessfulTag)

          git merge-base --is-ancestor $lastTagCommitId $tagCommitId
          if [ $? != 0 ]; then
              present="false"
          fi
        fi
    done

    echo "$present"
}

function inititialCheckin() {
  tag=$1
  cd "$REPO"
  git fetch --tag root $tag
  git checkout master
  git merge $tag
  git tag -d $tag

  for module in "${MODULES[@]}" ; do
      cd "$MIRROR/$module/";
      commitId=$(git rev-list -n 1  $tag)
      cd "$REPO"
      git checkout master
      /usr/lib/git-core/git-subtree add --prefix=$module "$MIRROR/$module/" $tag
      #/usr/lib/git-core/git-subtree split --prefix=$module --annotate="($module split)" --branch "$module-branch"
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
    #git fetch "$MIRROR/root/"
    #lastCommit=$(git rev-list -n 1  HEAD)
    #git rebase FETCH_HEAD


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

doReset="false"

while getopts "urs:e:" opt; do
    case "${opt}" in
        u)
            updateMirrors
            exit
            ;;
        r)
            doReset="true"
            ;;
        s)
            startTag=${OPTARG}
            ;;
        e)
            endTag=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))


if [ "$doReset" == "true" ]; then
  initRepo
  inititialCheckin $startTag

  git tag | while read tag
  do
    git tag -d $tag;
  done

  git tag "$startTag"
  exit
fi


count=1

cd "$MIRROR/root"
export lastSuccessfulTag="$startTag"

#for tag in $(git log --topo-order --oneline --decorate --simplify-by-decoration --ancestry-path $startTag..$endTag | egrep -o "tag: [0-9A-Za-z-]+" | tac | cut -f2 -d' ');
for tag in $startTag $endTag
do
  cd "$MIRROR/root"
  failed="false"

    echo $tag
    present=$(canMergeTag "$tag" "$lastSuccessfulTag")

    if [ "$present" == "true" ]; then

        cd "$REPO"

        echo "$tag" >> /tmp/mergedTags
        count=$(($count + 1));
        if [ $(($count % 20)) == 0 ]; then
                git prune
                git gc
        fi

        cd "$MIRROR/root/";
        commitId=$(git rev-list -n 1  $tag)
        cd "$REPO"
        git checkout master

        git tag -d $tag || true
        git fetch -q root $tag


        set +e
        git merge -q -m "Merge root at $tag" $commitId

        if [[ "$?" -ne "0" ]]; then
           if [ "$(git diff --name-only --diff-filter=U | wc -l)" == "1" ] && [ "$(git diff --name-only --diff-filter=U)" == "common/autoconf/generated-configure.sh" ];
           then
                chmod +x ./common/autoconf/autogen.sh
                ./common/autoconf/autogen.sh
                git commit -a --no-edit
           else
                git reset --hard $lastSuccessfulTag
                failed="true"
                continue
           fi
        fi
        set -e

        lastCommit=$(git rev-list -n 1  HEAD)
        #git rebase -X theirs --onto master $lastCommit FETCH_HEAD

        for module in "${MODULES[@]}" ; do
            if [ "$failed" == "true" ]; then
              continue;
            fi
            cd "$MIRROR/$module/";

            commitId=$(git rev-list -n 1  $tag)

            cd "$REPO"

            #git fetch "$module-repo" $commitId

            set +e
            /usr/lib/git-core/git-subtree pull -q -m "Merge $module at $tag" --prefix=$module "$MIRROR/$module/" $tag

            if [[ "$?" -ne "0" ]]; then
                git reset --hard $lastSuccessfulTag
                failed="true"
            fi
            set -e
        done
        echo "Success $tag" >> /tmp/mergedTags

        cd "$REPO"
        lastSuccessfulTag="$tag"
        git tag  -d "$tag" || true
        git tag  -f "$tag"
    else
        echo "Skipping $tag due to not being present"
    fi

    if [ "$endTag" == "$tag" ];
    then
      exit 0
    fi
done