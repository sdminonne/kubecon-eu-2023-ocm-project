#!/usr/bin/env bash

. demo-magic.sh

. common.sh

command -v clusteradm >/dev/null 2>&1 || { log::error >&2 "can't find clusteradm.  Aborting."; exit 1; }
#check pre-requisities: TODO check version
command -v argocd >/dev/null 2>&1 || { log::error >&2 "can't find argocd. Aborting."; exit 1; }


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

#############################
# Register managed clusters
#############################

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



#################################
# Install ArgoCD on all cluters
#################################
for currentcluster in ${clusters[@]};
do
    pe "kubectl --context $(get_client_context_from_cluster_name ${currentcluster}) create namespace argocd"
    pe "kubectl --context $(get_client_context_from_cluster_name ${currentcluster}) apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/core-install.yaml"
done



#scale down the argocd on the HUB
pe "kubectl --context  $(get_client_context_from_cluster_name ${HUB}) -n argocd scale statefulset/argocd-application-controller --replicas 0"



#Deploy the argocd-pull-model
git clone https://github.com/sdminonne/argocd-pull-integration.git
cd argocd-pull-integration/
make deploy
cd ..


pe "kubectl  --context  $(get_client_context_from_cluster_name ${HUB}) -n argocd get deploy"


for managedcluster in ${managedclusters[@]};
do
    cat <<EOF > /tmp/argocd-secret-${managedcluster}.yaml
apiVersion: v1
kind: Secret
metadata:
  name: ${managedcluster}-secret # cluster1-secret
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: cluster
type: Opaque
stringData:
  name: ${managedcluster} # cluster1
  server: https://${managedcluster}-control-plane:6443 # https://cluster1-control-plane:6443
EOF

    pe " cat /tmp/argocd-secret-${managedcluster}.yaml"
    pe "kubectl --context  $(get_client_context_from_cluster_name ${HUB}) apply -f /tmp/argocd-secret-${managedcluster}.yaml"

done

pe "kubectl --context  $(get_client_context_from_cluster_name ${HUB}) get secrets -n argocd"



pe "kubectl  --context  $(get_client_context_from_cluster_name ${HUB}) apply -f argocd-pull-integration/example/hub"

for managedcluster in ${managedclusters[@]};
do
    pe "kubectl --context  $(get_client_context_from_cluster_name ${managedcluster}) apply -f argocd-pull-integration/example/managed"
done

pe "kubectl --context  $(get_client_context_from_cluster_name ${HUB}) apply -f argocd-pull-integration/example/guestbook-app-set.yaml"

pe "kubectl  --context  $(get_client_context_from_cluster_name ${HUB})  -n argocd get appset"

pe "kubectl --context  $(get_client_context_from_cluster_name ${HUB})  -n argocd get app"

for managedcluster in ${managedclusters[@]};
do
    pe "kubectl --context  $(get_client_context_from_cluster_name ${HUB})  -n ${managedcluster} get manifestwork"
done

for managedcluster in ${managedclusters[@]};
do
    pe "kubectl --context $(get_client_context_from_cluster_name ${managedcluster}) -n argocd get app"
done


pe "kubectl --context  $(get_client_context_from_cluster_name ${HUB}) -n argocd get app"
