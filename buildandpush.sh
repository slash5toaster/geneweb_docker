#!/usr/bin/env bash

[[ $DEBUG ]] && set -x
set -o pipefail

D2S_VERSION=v3.7.0

declare -a LABEL_NAMES
declare -a REMOTE_LNK

LABEL_NAMES=(
             PROJECT
             NAME
             VERSION
             MAINTAINER
             GENERATE_SINGULARITY_IMAGE
             )
REMOTE_LNK=(
            localhost:5000
            )

ACTION=${1:-"nothing"}

#Sanity Check

# ensure Dockerfile is there
if [[ ! -e "Dockerfile" ]]; then
  echo "$(basename $0) *must* be co-located with the Dockerfile"
  exit 13
fi

# ensure labels are present
for (( i = 0; i < ${#LABEL_NAMES[@]}; i++ )); do
  if [[ $(grep LABEL Dockerfile | grep -ic ${LABEL_NAMES[$i]}) -eq 0 ]]; then
    echo "Make sure the ${LABEL_NAMES[$i]} label is set in the Dockerfile."
    echo "N.B. labels are case sensitive and the must follow the pattern"
    echo "LABEL \"labelname\"=\"value\""
    exit 23
  fi
done

#pull the name from the docker file - these labels *MUST* be set
CONTAINER_PROJECT=${CONTAINER_PROJECT:-$(grep LABEL Dockerfile | grep PROJECT | cut -d = -f2 | tr -d '"')}
CONTAINER_NAME=${CONTAINER_NAME:-$(grep LABEL Dockerfile | grep NAME | cut -d = -f2 | tr -d '"')}
CONTAINER_TAG=${CONTAINER_TAG:-$(grep LABEL Dockerfile | grep VERSION | cut -d = -f2| tr -d '"')}
CONTAINER_STRING="${CONTAINER_PROJECT}/${CONTAINER_NAME}:${CONTAINER_TAG}"

delay_time ()
{
    local TITLE=${1:-"Building"}

    echo "${TITLE} ${CONTAINER_STRING} in 5"
    for (( i = 1; i <= 5; i++ )); do
      echo -en "$i "
      sleep 1
    done
    echo -en "\n Starting\n .....\n\n"
}
build_local ()
{
  mkdir -vp source/logs/
  delay_time "Build locally -"
  mkdir -vp  source/logs/
  docker build . \
         -t ${CONTAINER_STRING} \
         --label BUILDDATE=$(date +%F-%H%M) \
    | tee source/logs/build-${CONTAINER_PROJECT}-${CONTAINER_NAME}_${CONTAINER_TAG}-$(date +%F-%H%M).log && \
  docker inspect ${CONTAINER_STRING} > source/logs/inspect-${CONTAINER_PROJECT}-${CONTAINER_NAME}_${CONTAINER_TAG}-$(date +%F-%H%M).log
}

push_remote ()
{
  delay_time "Pushing remote"
  for (( i = 0; i < ${#REMOTE_LNK[@]}; i++ ));
  do
    # ensure the remote is up before attempting to tag and push
    if [[ $(wget -q --tries=2 --timeout=2 --spider ${REMOTE_LNK[${i}]} && echo "there") == "there" ]]; then
      docker tag ${CONTAINER_STRING} ${REMOTE_LNK[${i}]}/${CONTAINER_STRING}
      docker push ${REMOTE_LNK[i]}/${CONTAINER_STRING}
    else
      echo "${REMOTE_LNK[${i}]} not responding"
    fi
  done
}

build_singularity ()
{
  local OUTPUT_FOLDER=$(pwd)

  delay_time "Building singularity container in ${OUTPUT_FOLDER}"

  docker run -v /var/run/docker.sock:/var/run/docker.sock \
             -v ${OUTPUT_FOLDER}:/output \
             --privileged -t --rm \
             quay.io/singularity/docker2singularity:${D2S_VERSION} \
             ${CONTAINER_STRING}
}

# Do some stuff

case ${ACTION} in
  local)
      build_local
    ;;
  remote)
      # build locally if it doesn't already exist
      # this assumes the format of the docker image command
      if [[ $( docker images | tr -s ' ' ':' | grep -c ^${CONTAINER_STRING}) ]]; then
        echo ${CONTAINER_STRING} "exists locally"
      else
        build_local
      fi
      push_remote
    ;;
  singularity)
      # build locally if it doesn't already exist
      # this assumes the format of the docker image command
      if [[ $( docker images | tr -s ' ' ':' | grep -c ^${CONTAINER_STRING}) ]]; then
        echo ${CONTAINER_STRING} "exists locally"
      else
        build_local
      fi
      build_singularity
    ;;
  all)
      build_local
      push_remote
      build_singularity
    ;;
  run)
      # this assumes the format of the docker image command
      if [[ $( docker images | tr -s ' ' ':' | grep -c ^${CONTAINER_STRING}) ]]; then
        docker run --rm \
                   -it \
                   -e DEBUG=0 \
                   -v $(pwd):/opt/devel \
                   ${CONTAINER_STRING} bash
      else
        echo ${CONTAINER_STRING} "doesn't exist"
      fi
    ;;
  list)
      # this assumes the format of the docker image command
      if [[ $( docker images | tr -s ' ' ':' | grep -c ^${CONTAINER_STRING}) ]]; then
        echo ${CONTAINER_STRING}
      else
        echo ${CONTAINER_STRING} "not yet built"
      fi
    ;;
  help|h)
    echo "Please use $(basename $0) local|remote|singularity|all|run|list "
    echo "   local - builds only the local container"
    echo "   remote - builds and tags the local + remote container"
    echo "   singularity - builds the singularity image from the local container"
    echo "   all - as implied"
    echo "   run - runs the container with 'docker run --rm -it -v $(pwd):/opt/devel ${CONTAINER_STRING}'"
    echo "   list - list the container to be built"
    ;;
  *)
    ./$(basename ${0}) help
    ;;
esac

#### End of File, if this is missing the file has been truncated
