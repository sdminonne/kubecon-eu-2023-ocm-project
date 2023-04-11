#!/usr/bin/env bash

. demo-magic.sh

. common.sh

# https://open-cluster-management.io/getting-started/integration/policy-framework/
#for policy placement rule we need Aplication Management
#See-> https://open-cluster-management.io/getting-started/integration/app-lifecycle/

echo "Application lifecycile management need to be installed"
clusteradm install hub-addon --names application-manager --context ${HUBCTX}
kubectl -n open-cluster-management get deploy multicluster-operators-subscription --context ${HUBCTX}

#Create the open-cluster-management-agent-addon namespace on the managed cluster.
kubectl create ns open-cluster-management-agent-addon --context ${MANAGEDCTX} --context ${HUBCTX}

#Deploy the subscription add-on in corresponding managed cluster namespace on the hub cluster.
clusteradm --context ${HUBCTX} addon enable --names application-manager --clusters ${MANAGEDCTX}
kubectl -n ${MANAGEDCTX} get managedclusteraddon --context ${HUBCTX}

#Check the the subscription add-on deployment on the managed cluster.
kubectl -n open-cluster-management-agent-addon get deploy --context ${MANAGEDCTX}


###################################
#Now the placment rules framework
##################################

## Install the governance-policy-framework hub components

#Deploy the policy framework controllers to the hub cluster
clusteradm install hub-addon --names governance-policy-framework --context  ${HUBCTX}
#Ensure the pods are running on the hub with the following command
kubectl get pods -n  open-cluster-management --context  ${HUBCTX}


## Deploy the synchronization components to the managed cluster(s)

# deploy the synchronization components to a managed cluster
clusteradm addon enable --names governance-policy-framework --clusters ${MANAGEDCTX} --context ${HUBCTX}
#Verify that the governance-policy-framework-addon controller pod is running on the managed cluster with the following command
kubectl get pods -n open-cluster-management-agent-addon --context  ${MANAGEDCTX}


## Install the policy controllers

# Deploy the configuration policy controller
clusteradm addon enable addon --names config-policy-controller --clusters ${MANAGEDCTX}  --context ${HUBCTX}
#Ensure the pod is running on the managed cluster with the following command:
kubectl get pods -n open-cluster-management-agent-addon  --context ${MANAGEDCTX}



## Placement Rule API


kubectl --context ${HUBCTX} apply -n default -f https://raw.githubusercontent.com/open-cluster-management/policy-collection/main/stable/CM-Configuration-Management/policy-pod.yaml

#Update the PlacementRule to distribute the policy to the managed cluster with the following command (this clusterSelector will deploy the policy to all managed clusters):
kubectl --context ${HUBCTX}  patch -n default placementrule.apps.open-cluster-management.io/placement-policy-pod --type=merge -p "{\"spec\":{\"clusterSelector\":{\"matchExpressions\":[]}}}"

#To confirm the the policy has been applied to cluster1
kubectl --context ${HUBCTX} get -n default placementrule.apps.open-cluster-management.io/placement-policy-pod -o yaml


#Final steps to apply the policy
# Enforce the policy to make the configuration policy automatically correct any misconfigurations on the managed cluster:
kubectl --context ${HUBCTX}  patch -n default policy.policy.open-cluster-management.io/policy-pod --type=merge -p "{\"spec\":{\"remediationAction\": \"enforce\"}}"
kubectl  --context ${MANAGEDCTX} get policy -A

kubectl  --context ${MANAGEDCTX} get pods -n default
