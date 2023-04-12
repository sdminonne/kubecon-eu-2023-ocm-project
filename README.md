# kubecon EU 2023 open-cluster-management.io Project

This repository contains file for the open-cluster-management.io project at Kubecon EU 2023.

It makes use of https://github.com/paxtonhare/demo-magic to automate the demo
To run the demo (working on minikube):


boostrap the minikube infrastructure. Three clusters (hub, cluster1, cluster2). this share the same network so cluster see each other.

```shell
$ ./00-boostrap-minikube-infra.sh
....
```
The script `./01-check-minikube-infra-connectivity.sh ` shows the cluster see each other it simply create three pods and run a `kubectl cluster-info` against the other clusters.

```shell
$ ./01-check-minikube-infra-connectivity.sh
```

Then the `demo.sh` effectively runs the demo...

```shell
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
