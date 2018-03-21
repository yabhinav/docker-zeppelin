#!/bin/bash
#
# Author : Abhinav Y <https:yabhinav-github.com>
#
# Runs tests for a Docker container image build
# Environment variables distribution and version must be set
# See usage() for details.

#{{{ Bash settings
# abort on nonzero exitstatus
set -o errexit
# abort on unbound variable
set -o nounset
# don't hide errors within pipes
set -o pipefail
#}}}

#{{{ Variables
DOCKER_USERNAME=${DOCKER_USERNAME:-yabhinav}
IMAGE_NAME=${IMAGE_NAME:-${DOCKER_USERNAME}/zeppelin}
IMAGE_TAG=${IMAGE_TAG:-latest}
VERSION=$(cat version.txt)
CONTAINERNAME=${CONTAINERNAME:-zeppelin}

VARIATION="minimal all"
#}}}

#{{{ Helper functions
log() {
  local yellow='\e[0;33m'
  local reset='\e[0m'

  printf "${yellow}>>> %s${reset}\n" "${*}"
}

function build() {
  # Tag each variation
  for t in $VARIATION; do
    docker build -t ${IMAGE_NAME}:$VERSION-${t} ${t}
  done
  # Tag complete variation as default/latest
  docker tag $IMAGE_NAME:$VERSION-all $IMAGE_NAME:latest

  if [ $(docker images | grep -c $IMAGE_NAME) -lt 3 ] ; then
    log "Missing Tags ..rebuild later"
    exit 1
  else
    log "Docker Image : $IMAGE_NAME Build(s) successfull for Zeppelin Version : $VERSION "
  fi
  log "Built Images are : "
  docker images | grep --color $IMAGE_NAME
  exit 0
}

function run() {
  local version=${1:-$IMAGE_TAG}
  shift
  local name=${1:-$CONTAINERNAME}
  shift
  # if [$1 != ''] ; then shift fi
  log "docker run -d -p 8080:8080 -p 4040:4040 --name=${name} ${IMAGE_NAME}:${version}"
  docker run -d -p 8080:8080 -p 4040:4040 --name=${name} ${IMAGE_NAME}:${version} "$@"
}

status() {
  local version=${1:-$IMAGE_TAG}
  shift
  local name=${1:-$CONTAINERNAME}
  shift
  log "Checking if Docker Instance : ${name} is running"
  if $(docker inspect -f {{.State.Running}} ${name}) ; then
    containerID=$(docker inspect -f {{.ID}} ${name})
    image=$(docker inspect -f {{.Config.Image}} ${name})
    if [ "${image}" == "${IMAGE_NAME}:${version}" ]; then
      log "Container Found and Running ...ContainerID : ${containerID} ...Image : ${image} "
      log "Docker Tests successfull."
      exit 0
    else
      log "Docker Tests Failed : Container found but wrong Image : ${image}"
      exit 1
    fi
  else
    log "Docker Tests Failed : Container not running must be faulty start/init"
    exit 1
  fi
}

cleanup() {
  local name=${1:-$CONTAINERNAME}
  log "Removing Docker Container : ${name} "
  docker stop ${name}
  docker rm ${name}
}

trap cleanup INT ERR HUP TERM #Dont cleanup on EXIT

#}}}

function main() {
  local command=$1
  shift
  case $command in
    build)    build "$@" ;;
    run)      run "$@" ;;
    status)   status "$@" ;;
    cleanup)  cleanup "$@" ;;
    *)        log "Usage: $0 (build|run|status|cleanup)" ;;
  esac
}

main "$@"
