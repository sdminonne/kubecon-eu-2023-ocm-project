#!/usr/bin/env bash
. demo-magic.sh



. common.sh

#check pre-requisities: TODO check version
command -v clusteradm >/dev/null 2>&1 || { log::error >&2 "can't find clusteradm.  Aborting."; exit 1; }

HUBIP=$(minikube -p $HUBCTX ip)
HUBURL=https://${HUBIP}:8443

pe "clusteradm init --wait --context ${HUBCTX}"
