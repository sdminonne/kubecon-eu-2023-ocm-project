#!/usr/bin/env bash

. demo-magic.sh

. common.sh




pe "cat manifestwork.yaml"

pe "kubectl --context ${MANAGEDCTX} get ns"

pe "kubectl --context ${HUBCTX} apply -f manifestwork.yaml"

pe "kubectl --context ${MANAGEDCTX} get ns"

pe "kubectl --context ${MANAGEDCTX} logs world -n hello"

cmd
