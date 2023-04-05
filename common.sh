#!/usr/bin/env bash

SUFFIX="-keu-23"

HUBCTX=hub${SUFFIX}
MANAGEDCTX=cluster1${SUFFIX}
export KUBECONFIG=$(pwd)/kubeconfig${SUFFIX}

declare -a clusters=("hub${SUFFIX}" "cluster1${SUFFIX}")

wait_until() {
  local script=$1
  local wait=${2:-.5}
  local timeout=${3:-10}
  local i

  script_pretty_name=$(echo "$script" | sed 's/_/ /g')
  times=$(echo "($(bc <<< "scale=2;$timeout/$wait")+0.5)/1" | bc)
  for i in $(seq 1 "$times"); do
    local out=$($script)
    if [ "$out" == "0" ]
    then
      log::info "${script_pretty_name}: OK"
      return 0
    fi
    log::warning "${script_pretty_name}: Waiting..."
    sleep $wait
  done
  log::error "${script_pretty_name}"
  return 1
}

my-kubectl_pod_running() {
    local context=$1
    podstatus=$(kubectl --context=$context get pod my-kubectl -o jsonpath='{.status.phase}')
    if [[ "${podstatus}" == "Running" ]]
    then
        echo "0"
        return
    fi
    echo "1"
}

#Log in RED
log::error() {
  printf "\033[0;31m%s\033[0m\n" "ERROR: $1"
}

#Log in yellow
log::warning() {
  printf "\033[1;33m%s\033[0m\n" "WARNING: $1"
}

#Log in green
log::info() {
  printf "\033[0;32m%s\033[0m\n" "INFO: $1"
}
