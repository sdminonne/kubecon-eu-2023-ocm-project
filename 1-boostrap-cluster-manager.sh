#!/usr/bin/env bash
. demo-magic.sh



. common.sh

#check pre-requisities: TODO check version
command -v clusteradm >/dev/null 2>&1 || { log::error >&2 "can't find clusteradm.  Aborting."; exit 1; }

pe "clusteradm init --wait --context $(get_client_context_from_cluster_name ${HUB})"

pe "kubectl -n open-cluster-management get pod --context  $(get_client_context_from_cluster_name ${HUB})"
