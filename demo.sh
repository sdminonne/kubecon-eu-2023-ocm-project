#!/usr/bin/env bash

. demo-magic.sh

. common.sh

command -v clusteradm >/dev/null 2>&1 || { log::error >&2 "can't find clusteradm.  Aborting."; exit 1; }

HUBIP=$(minikube -p ${HUB} ip)
HUBURL=https://${HUBIP}:8443



commaseparatedmanagedcluster=""
delim=""
for item in "${managedclusters[@]}"; do
  commaseparatedmanagedcluster="$commaseparatedmanagedcluster$delim$item"
  delim=","
done


clear

#################################
# Initialize the cluster manager
#################################

echo "Init the cluster manager on the ${HUB}"
pe "clusteradm init --wait --context $(get_client_context_from_cluster_name ${HUB})"

echo "Show pod is running on the ${HUB}"
pe "kubectl -n open-cluster-management get pod --context  $(get_client_context_from_cluster_name ${HUB})"

TOKEN=$(clusteradm --context $(get_client_context_from_cluster_name ${HUB}) get token | awk -F "=" '/token=/ {print $2}')

TYPE_SPEED=200
for managedcluster in ${managedclusters[@]};
do
    pe "clusteradm --context $(get_client_context_from_cluster_name ${managedcluster}) join --hub-token ${TOKEN} --hub-apiserver ${HUBURL} --wait --cluster-name ${managedcluster}";
done
TYPE_SPEED=30

echo "How did we get the token?"
echo 'clusteradm --context ... get token | awk'

pe "kubectl --context $(get_client_context_from_cluster_name ${HUB}) get managedclusters"

pe "kubectl get csr --context $(get_client_context_from_cluster_name ${HUB})"
pe "clusteradm --context  $(get_client_context_from_cluster_name ${HUB}) accept --clusters ${commaseparatedmanagedcluster}"
pe "kubectl get csr --context $(get_client_context_from_cluster_name ${HUB})"

pe "kubectl --context $(get_client_context_from_cluster_name ${HUB}) get managedclusters"



#####################
# Apply Manifestwork
#####################

for managedcluster in ${managedclusters[@]};
do
    cat << EOF > /tmp/mw-${managedcluster}.yaml
apiVersion: work.open-cluster-management.io/v1
kind: ManifestWork
metadata:
  name: mw-${managedcluster}
  namespace: ${managedcluster}
spec:
  workload:
    manifests:
      - apiVersion: v1
        kind: Namespace
        metadata:
          name: hello
      - apiVersion: v1
        kind: Pod
        metadata:
          name: world
          namespace: hello
        spec:
          containers:
            - name: hello
              image: busybox
              args:
              - sh
              - -c
              - echo "Hello, Kubernetes!" && sleep 3600
          restartPolicy: OnFailure
EOF

    pe " cat /tmp/mw-${managedcluster}.yaml"
    pe "kubectl --context $(get_client_context_from_cluster_name ${managedcluster}) get ns";
    pe "kubectl --context $(get_client_context_from_cluster_name ${HUB}) apply -f /tmp/mw-${managedcluster}.yaml";
    pe "kubectl --context $(get_client_context_from_cluster_name ${managedcluster}) get ns";
    pe "kubectl --context $(get_client_context_from_cluster_name ${managedcluster}) logs world -n hello";
done

###########################
# Now policies
###########################

# For policy placement rule we need application management
echo "Application lifecycle management need to be installed"

pe "clusteradm install hub-addon --names application-manager --context $(get_client_context_from_cluster_name ${HUB})"
pe "kubectl -n open-cluster-management get deploy multicluster-operators-subscription --context $(get_client_context_from_cluster_name ${HUB})"

echo "Create the open-cluster-management-agent-addon namespace on the managed cluster."
for managedcluster in ${managedclusters[@]};
do
    kubectl --context  $(get_client_context_from_cluster_name ${managedcluster}) get ns open-cluster-management-agent-addon
    [ $? -eq 0 ] || (pe "kubectl create ns open-cluster-management-agent-addon --context $(get_client_context_from_cluster_name ${managedcluster})");
done

#Deploy the subscription add-on in corresponding managed cluster namespace on the hub cluster.
pe "clusteradm --context $(get_client_context_from_cluster_name ${HUB}) addon enable --names application-manager --clusters ${commaseparatedmanagedcluster} "

for managedcluster in ${managedclusters[@]};
do
    #kubectl -n ${managedcluster} get managedclusteraddon application-manager --context $(get_client_context_from_cluster_name ${HUB}) -o jsonpath='{.status.conditions[?(@.type=="Available")].status}'
    #TODO: add wait_until
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

pe "kubectl --context $(get_client_context_from_cluster_name ${HUB}) apply -n default -f demo/policy-pod.yaml"

#Update the PlacementRule to distribute the policy to the managed cluster with the following command (this clusterSelector will deploy the policy to all managed clusters):
pe "kubectl --context $(get_client_context_from_cluster_name ${HUB}) patch -n default placementrule.apps.open-cluster-management.io/placement-policy-pod --type=merge -p \"{\\\"spec\\\":{\\\"clusterSelector\\\":{\\\"matchExpressions\\\":[]}}}\""


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
