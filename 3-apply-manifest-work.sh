#!/usr/bin/env bash

. demo-magic.sh

. common.sh




#pe "cat manifestwork.yaml"

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
