#!/usr/bin/env bash

. demo-magic.sh

. common.sh

#check pre-requisities: TODO check version
command -v clusteradm >/dev/null 2>&1 || { log::error >&2 "can't find clusteradm.  Aborting."; exit 1; }

HUBIP=$(minikube -p $HUBCTX ip)
HUBURL=https://${HUBIP}:8443

echo HUBCTX=${HUBCTX}
echo MANAGEDCTX=${MANAGEDCTX}

TOKEN=$(clusteradm --context ${HUBCTX} get token | awk -F "=" '/token=/ {print $2}')

pe "clusteradm --context ${MANAGEDCTX} join --hub-token ${TOKEN} --hub-apiserver ${HUBURL} --wait --cluster-name ${MANAGEDCTX} --context ${MANAGEDCTX}"

#TODO wait for CSR to be approved
#kubectl get csr -w --context ${HUBCTX}"

pe "kubectl get csr --context ${HUBCTX}"

pe "clusteradm --context  ${HUBCTX} accept --clusters ${MANAGEDCTX}"

pe "kubectl get csr --context ${HUBCTX}"

cmd
