#!/usr/bin/env bash




# Set up the workspace to work from
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
mkdir -p $SCRIPT_DIR/workspace
WORKSPACE=$SCRIPT_DIR/workspace

# REPO_LOCATION     - workspace/adoptopenjdk-clone/      - copy of upstream github repo where new commits will end up
# MIRROR            - workspace/openjdk-clean-mirror     - Unmodified clones of openjdk mercurial (basically a local cache)
# REWRITE_WORKSPACE - workspace/openjdk-rewritten-mirror - Workspace where mercurial is manipulated before being written into the upstream
#                   - workspace/bin                      - Helper third party programs
MIRROR=$WORKSPACE/openjdk-clean-mirror
REWRITE_WORKSPACE=$WORKSPACE/openjdk-rewritten-mirror/
REPO_LOCATION=$WORKSPACE/adoptopenjdk-clone/



# These the the modules in the mercurial forest that we'll have to iterate over
MODULES=(corba langtools jaxp jaxws nashorn jdk hotspot)




#g=branch with patches
#c74b3a8efdcfd681fcee9f8e3ee23047addb3171=commit before divergence
#master=head of what to merge in
#git rebase --onto g c74b3a8efdcfd681fcee9f8e3ee23047addb3171 master
#git rebase -X theirs --onto g c74b3a8efdcfd681fcee9f8e3ee23047addb3171 d58a3f865a88a6302c1fd76d6532ec0c9457d29f

## logs in topological order
git log --topo-order --pretty=format:"%H"
