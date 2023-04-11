#!/usr/bin/env bash

. demo-magic.sh




. common.sh


commaseparatedmanagedcluster=""
delim=""
for item in "${managedclusters[@]}"; do
  commaseparatedmanagedcluster="$commaseparatedmanagedcluster$delim$item"
  delim=","
done



# https://open-cluster-management.io/getting-started/integration/policy-framework/
#for policy placement rule we need Aplication Management
#See-> https://open-cluster-management.io/getting-started/integration/app-lifecycle/

echo "Application lifecycile management need to be installed"

pe "clusteradm install hub-addon --names application-manager --context $(get_client_context_from_cluster_name ${HUB})"
pe "kubectl -n open-cluster-management get deploy multicluster-operators-subscription --context $(get_client_context_from_cluster_name ${HUB})"

#Create the open-cluster-management-agent-addon namespace on the managed cluster.
for managedcluster in ${managedclusters[@]};
do
    pe "kubectl create ns open-cluster-management-agent-addon --context $(get_client_context_from_cluster_name ${managedcluster}) --context $(get_client_context_from_cluster_name ${HUB})";
done
#TODO CHECK THIS


#Deploy the subscription add-on in corresponding managed cluster namespace on the hub cluster.
pe "clusteradm --context $(get_client_context_from_cluster_name ${HUB}) addon enable --names application-manager --clusters ${commaseparatedmanagedcluster}"
for managedcluster in ${managedclusters[@]};
do
    pe "kubectl -n ${managedcluster} get managedclusteraddon --context $(get_client_context_from_cluster_name ${HUB})";
done

#Check the the subscription add-on deployment on the managed cluster.
for managedcluster in ${managedclusters[@]};
do
    pe "kubectl -n open-cluster-management-agent-addon get deploy --context $(get_client_context_from_cluster_name ${managedcluster})";
done

###################################
#Now the placment rules framework
##################################

## Install the governance-policy-framework hub components

#Deploy the policy framework controllers to the hub cluster
pe "clusteradm install hub-addon --names governance-policy-framework --context  $(get_client_context_from_cluster_name ${HUB})"
#Ensure the pods are running on the hub with the following command
pe "kubectl get pods -n  open-cluster-management --context  $(get_client_context_from_cluster_name ${HUB})"


## Deploy the synchronization components to the managed cluster(s)

# deploy the synchronization components to a managed cluster
pe "clusteradm addon enable --names governance-policy-framework --clusters ${commaseparatedmanagedcluster} --context $(get_client_context_from_cluster_name ${HUB})"
#Verify that the governance-policy-framework-addon controller pod is running on the managed cluster
for managedcluster in ${managedclusters[@]};
do
    pe "kubectl get pods -n open-cluster-management-agent-addon --context $(get_client_context_from_cluster_name ${managedcluster})"
done

## Install the policy controllers

# Deploy the configuration policy controller
pe "clusteradm addon enable addon --names config-policy-controller --clusters ${commaseparatedmanagedcluster}  --context $(get_client_context_from_cluster_name ${HUB})"
#Ensure the pod is running on the managed cluster with the following command:
for managedcluster in ${managedclusters[@]};
do
    pe "kubectl get pods -n open-cluster-management-agent-addon  --context $(get_client_context_from_cluster_name ${managedcluster})"
done


## Placement Rule API


pe "kubectl --context $(get_client_context_from_cluster_name ${HUB}) apply -n default -f https://raw.githubusercontent.com/open-cluster-management/policy-collection/main/stable/CM-Configuration-Management/policy-pod.yaml"

#Update the PlacementRule to distribute the policy to the managed cluster with the following command (this clusterSelector will deploy the policy to all managed clusters):
pe "kubectl --context $(get_client_context_from_cluster_name ${HUB})" patch -n default placementrule.apps.open-cluster-management.io/placement-policy-pod --type=merge -p \"{\\\"spec\\\":{\\\"clusterSelector\\\":{\\\"matchExpressions\\\":[]}}}\""
#To confirm the the policy has been applied to cluster1 and 2
pe "kubectl --context $(get_client_context_from_cluster_name ${HUB}) get -n default placementrule.apps.open-cluster-management.io/placement-policy-pod -o yaml"


#Final steps to apply the policy
# Enforce the policy to make the configuration policy automatically correct any misconfigurations on the managed cluster:
pe "kubectl --context $(get_client_context_from_cluster_name ${HUB})  patch -n default policy.policy.open-cluster-management.io/policy-pod --type=merge -p \"{\\\"spec\\\":{\\\"remediationAction\\\": \\\"enforce\\\"}}\""



for managedcluster in ${managedclusters[@]};
do
    pe "kubectl  --context $(get_client_context_from_cluster_name ${managedcluster}) get policy -A"
    pe "kubectl  --context $(get_client_context_from_cluster_name ${managedcluster}) get pods -n default"
done
