#!/usr/bin/env bash

. demo-magic.sh

SUFFIX="-keu-23"

HUBCTX=hub-keu-23
MANAGEDCTX=cluster1-keu-23

export KUBECONFIG=$(pwd)/kubeconfig-keu-23


pei "kubectl --context ${HUBCTX} apply -f manifestwork.yaml"
