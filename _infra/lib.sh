#!/usr/bin/env bash


log::error() {
  printf "\033[0;31m%s\033[0m\n" "ERROR: $1"
}

log::warning() {
  printf "\033[1;33m%s\033[0m\n" "WARNING: $1"
}

log::info() {
  printf "\033[0;32m%s\033[0m\n" "INFO: $1"
}

command -v kubectl >/dev/null 2>&1 || { log::error >&2 "can't find kubectl.  Aborting."; exit 1; }
command -v minikube  >/dev/null 2>&1 || { log::error >&2 "can't find minikube.  Aborting."; exit 1; }

containerRuntime=$(minikube config get container-runtime )
[[ "${containerRuntime}" == "cri-o" ]] || { log::error >&2 "Container runtime should be cri-o"; exit 1; }

driver=$(minikube config get driver )
[[ "${driver}" == "kvm2" ]] || { log::error >&2 "Driver should be kvm2. While it looks ${driver}"; exit 1; }




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

minikube_up_and_running() {
    local profile=$1
    apiStatus=$(minikube -p $profile status --format='{{ .APIServer }}')
  hostStatus=$(minikube -p $profile status --format='{{ .Host }}')
  if [[ "${apiStatus}" == "Running" && "${hostStatus}" == "Running" ]]
  then
    echo "0"
    return
  fi
  echo "1"
}


minikube_stopped() {
  local profile=$1
  apiStatus=$(minikube -p $profile status --format='{{ .APIServer }}')
  hostStatus=$(minikube -p $profile status --format='{{ .Host }}')
  if [[ "${apiStatus}" == "Stopped" && "${hostStatus}" == "Stopped" ]]
  then
    echo "0"
    return
  fi
  echo "1"
}


fedora_pod_running() {
    local context=$1
    podstatus=$(kubectl --context=$context get pod fedora -o jsonpath='{.status.phase}')
    if [[ "${podstatus}" == "Running" ]]
    then
        echo "0"
        return
    fi
    echo "1"
}
