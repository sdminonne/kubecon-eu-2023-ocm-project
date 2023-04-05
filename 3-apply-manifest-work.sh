#!/usr/bin/env bash

. demo-magic.sh

. common.sh

pe "kubectl --context ${HUBCTX} apply -f manifestwork.yaml"

pe "kubectl --context ${MANAGEDCTX} logs hello -n default"
