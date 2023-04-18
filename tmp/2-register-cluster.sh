#!/usr/bin/env bash

. demo-magic.sh

. common.sh

commaseparatedmanagedcluster=""
delim=""
for item in "${managedclusters[@]}"; do
  commaseparatedmanagedcluster="$commaseparatedmanagedcluster$delim$item"
  delim=","
done



#check pre-requisities: TODO check version
command -v clusteradm >/dev/null 2>&1 || { log::error >&2 "can't find clusteradm.  Aborting."; exit 1; }

HUBIP=$(minikube -p $(get_client_context_from_cluster_name ${HUB}) ip)
HUBURL=https://${HUBIP}:8443


TOKEN=$(clusteradm --context $(get_client_context_from_cluster_name ${HUB}) get token | awk -F "=" '/token=/ {print $2}')

for managedcluster in ${managedclusters[@]};
do
    pe "clusteradm --context $(get_client_context_from_cluster_name ${managedcluster}) join --hub-token ${TOKEN} --hub-apiserver ${HUBURL} --wait --cluster-name ${managedcluster}";
done

pe "kubectl get csr --context $(get_client_context_from_cluster_name ${HUB})"

pe "clusteradm --context  $(get_client_context_from_cluster_name ${HUB}) accept --clusters ${commaseparatedmanagedcluster}"

pe "kubectl get csr --context $(get_client_context_from_cluster_name ${HUB})"
