#!/usr/bin/env bash

#export KUBECONFIG=$(mktemp)
#echo "KUBECONFIG $KUBECONFIG"

. common.sh
log::info "KUBECONFIG $KUBECONFIG"

#check pre-requisities: TODO check version
command -v kubectl >/dev/null 2>&1 || { log::error >&2 "can't find kubectl.  Aborting."; exit 1; }

#check pre-requisities: TODO check version
command -v minikube  >/dev/null 2>&1 || { log::error >&2 "can't find minikube.  Aborting."; exit 1; }

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


containerRuntime=$(minikube config get container-runtime )
[[ "${containerRuntime}" == "cri-o" ]] || { log::error >&2 "Container runtime should be cri-o"; exit 1; }

driver=$(minikube config get driver )
[[ "${driver}" == "kvm2" ]] || { log::error >&2 "Driver should be kvm2. While it looks ${driver}"; exit 1; }


for CLUSTERNAME in "${clusters[@]}"
do
   echo "Setting up clustername ${CLUSTERNAME}";
   minikube start -p ${CLUSTERNAME};
   wait_until "minikube_up_and_running ${CLUSTERNAME}"

done


for CLUSTERNAME in "${clusters[@]}"
do
  virsh net-dumpxml mk-${CLUSTERNAME}  > mk-${CLUSTERNAME}.xml;
  minikube stop -p ${CLUSTERNAME};
  wait_until "minikube_stopped ${CLUSTERNAME}"
  virsh net-destroy mk-${CLUSTERNAME};
done

for CLUSTERNAME in "${clusters[@]}"
do
   sed -i "/uuid/a \  <forward mode='route'/\>" mk-${CLUSTERNAME}.xml;
   virsh net-define mk-${CLUSTERNAME}.xml;
   virsh net-start mk-${CLUSTERNAME};
   echo "Waiting 10 seconds..."
   sleep 10 #TODO replace with wait-unitl
done

for CLUSTERNAME in "${clusters[@]}"
do
   minikube start -p ${CLUSTERNAME};
   wait_until "minikube_up_and_running ${CLUSTERNAME}"
done


kubectl config view --flatten > kubeconfig

#for CLUSTERNAME in "${clusters[@]}"
#do
#   kubectl --context ${CLUSTERNAME} cp ./kubeconfig my-kubectl:kubeconfig;
#   kubectl --context ${CLUSTERNAME} cp $(readlink -e $(which kubectl)) my-kubectl:kubectl;
#done

#for((i=0;i<${#clusters[@]};i++))
#do for((j=0;j<${#clusters[@]};j++))
#   do  [ "${clusters[$i]}" != "${clusters[$j]}" ] && kubectl --context=${clusters[$i]} exec -it my-kubectl -- /kubectl --kubeconfig=/kubeconfig --context=${clusters[$j]} cluster-info
#   done
#done

#for((i=0;i<${#clusters[@]};i++))
#do kubectl  --context=${clusters[$i]} delete pod my-kubectl
#done

#mv kubeconfig kubeconfig${SUFFIX}

exit
