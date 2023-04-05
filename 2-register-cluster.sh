#!/usr/bin/env bash

. demo-magic.sh

#check pre-requisities: TODO check version
command -v clusteradm >/dev/null 2>&1 || { log::error >&2 "can't find clusteradm.  Aborting."; exit 1; }

HUBCTX=hub-keu-23
MANAGEDCTX=cluster1-keu-23
HUBIP=$(minikube -p $HUBCTX ip)
HUBURL=https://${HUBIP}:8443

echo HUBCTX=${HUBCTX}
echo MANAGEDCTX=${MANAGEDCTX}

TOKEN=$(clusteradm --context ${HUBCTX} get token | awk -F "=" '/token=/ {print $2}')

pei "clusteradm --context ${MANAGEDCTX} join --hub-token ${TOKEN} --hub-apiserver ${HUBURL} --wait --cluster-name ${MANAGEDCTX} --context ${MANAGEDCTX}"

#TODO wait for CSR to be approved
#kubectl get csr -w --context ${HUBCTX}"



pei "clusteradm --context  ${HUBCTX} accept --clusters ${MANAGEDCTX}"

cmd
