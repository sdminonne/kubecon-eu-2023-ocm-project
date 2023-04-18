#!/usr/bin/env bash

. demo-magic.sh

. common.sh

#check pre-requisities: TODO check version
command -v clusteradm >/dev/null 2>&1 || { log::error >&2 "can't find clusteradm.  Aborting."; exit 1; }

pe "clusteradm unjoin --cluster-name ${MANAGEDCTX} --context ${MANAGEDCTX}"


pe "kubectl --context ${HUBCTX} delete -f manifestwork.yaml"


pe "clusteradm unjoin --cluster-name ${MANAGEDCTX} --context ${MANAGEDCTX}"
