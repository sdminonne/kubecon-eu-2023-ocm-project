# kubecon EU 2023 open-cluster-management.io Project

This repository contains file for the open-cluster-management.io project at Kubecon EU 2023.

It makes use of https://github.com/paxtonhare/demo-magic to automate the demo. Demos are runnable through two scripts `demo.sh` and `demo-argocd-pull-model.sh`. Demos have been tested and run on `minikube` environment more specifically with `kvm2` as driver and `cri-o` as container-runtime.


There's a script to boostrap the minikube infrastructure. It builds three clusters (hub, cluster1, cluster2). All the clusters share the same network so cluster see each other. The connection is bidirectional so even the HUB sees (cluster1 and cluster2) the managed clusters even if it's not required.

To bootstrap the minikube environment one has to run:

```shell
$ ./00-boostrap-minikube-infra.sh
....
```
The script `./01-check-minikube-infra-connectivity.sh ` shows the cluster see each other it simply create three pods and run a `kubectl cluster-info` against the other clusters.

```shell
$ ./01-check-minikube-infra-connectivity.sh
```

The `demo.sh` effectively runs the demo...

```shell
$ export KUBECONFIG=$(mktemp)
$ ./demo.sh
Init the cluster manager on the hub
$ clusteradm init --wait --context hub
CRD successfully registered.
Registration operator is now available.
ClusterManager registration is now available.
...
...
...
$ kubectl  --context cluster1 get policy -A
NAMESPACE   NAME                 REMEDIATION ACTION   COMPLIANCE STATE   AGE
cluster1    default.policy-pod   enforce              Compliant          30s
$ kubectl  --context cluster1 get pods -n default
NAME               READY   STATUS    RESTARTS   AGE
sample-nginx-pod   1/1     Running   0          9s
$ kubectl  --context cluster2 get policy -A
NAMESPACE   NAME                 REMEDIATION ACTION   COMPLIANCE STATE   AGE
cluster2    default.policy-pod   enforce              Compliant          40s
$ kubectl  --context cluster2 get pods -n default
NAME               READY   STATUS    RESTARTS   AGE
sample-nginx-pod   1/1     Running   0          20s
$
````


Another demo contained in this folder is `demo-argocd-pull-model.sh`.
Similarly:

```shell
$ export KUBECONFIG=$(mktemp)
$ demo-argocd-pull-model.sh
....
```
