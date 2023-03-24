# Cilium track

This repo acts as a summary of Cilium documentation.

## Prerequisites  

Run `bash ./scripts/deps.sh` to install the dependency if you are using ubuntu. 

### CNI 

Then run `bash ./scripts/k8s_setup.sh` to set up Kubernetes environments and CNI. You can choose `Cilium` or `Flannel` as CNI by changing the corresponding variables in `config.sh`.

After that, you can use `kubectl get nodes` to see whether all nodes are `READY`. You should check whether coredns is running by `kubectl get pods -n=kube-system`.

`cilium connectivity test` is a convenient way for sanity check.

## Servicemesh

### Istio with Cilium CNI

>Cilium’s Istio integration allows Cilium to enforce HTTP L7 network policies for mTLS protected traffic within the Istio sidecar proxies. In that sense, Cilium replace the CNI and possbily observability that originally using by Istio, but still keeps the Istio's powerful L7 traffic management features. [Full document here](https://docs.cilium.io/en/stable/network/istio/).

Run `bash ./scripts/cilium_istio_install.sh` do that.

### Istio with Flannel CNI

This is used to compare the performance.

Run `bash ./scripts/istio_install.sh`.

### Cilium control plane

#### L7 policy

> Functionality like L7 policies achieved by Enovy CRD, requires that `kube-proxy` is fully replaced by Cilium. In that case, the installation is quite differenet. [Full document here](https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/)

Instead of using `k8s_setup.sh`, we need to run `bash ./scripts/cilium_proxyless_install.sh` to both set Kubernates and Cilium environments. Then run the sanity checks to ensure `kube-proxy` is fully replaced.


```bash
kubectl -n kube-system exec ds/cilium -- cilium status | grep KubeProxyReplacement
# expect: KubeProxyReplacement:    Strict  

kubectl exec -it -n kube-system cilium-<your_pod_hash_val> -- cilium service list
# expect something like:
# ID   Frontend               Service Type   Backend
# [...]
# 4    10.104.239.135:80      ClusterIP      1 => 10.217.0.107:80
#                                            2 => 10.217.0.149:80
# 5    0.0.0.0:31940          NodePort       1 => 10.217.0.107:80
#                                            2 => 10.217.0.149:80
# 6    192.168.178.29:31940   NodePort       1 => 10.217.0.107:80
#                                            2 => 10.217.0.149:80
# 7    172.16.0.29:31940      NodePort       1 => 10.217.0.107:80
```

#### Hubble

As long as Cilium is installed, you can use `bash ./scripts/hubble.sh` to enable hubble and access its fancy UI. [More details here](https://docs.cilium.io/en/stable/gettingstarted/hubble/)


### Cleanup

I believe the best way is `sudo reboot`. 😄

## Example

We use bookinfo application to show the functionality and performance. To deploy the application:

```bash
kubectl apply -f ./k8s/bookinfo/bookinfo-v1.yaml

./wrk/wrk -t1 -c1 -d 10s http://10.96.88.88:9080 -L -s ./lua/gen.lua
```

To get experiment data, run `bash ./run.sh <suffix>`, the result will be saved to `./result/<data>.<suffix>.csv`.


## Functionalites

TODO 

### L3/L4 

Cilium provides some network policies.

### L7

#### North-South 

For ingress and egress traffic, Cilium supports Gateway API.

####  East-West

Cilium supports for L7 traffic management between pods is not as complete as Istio.

## Performance

We use bookinfo-v1 to test the performance.

## Reference

- Cilium [https://cilium.io/] and its Slack channel.
- Isovalent. There are many blogs that clearly illustrate the architecture about the service mesh. It helps build a high level understanding about Cilium, but somehow lacks codes and toturials. [https://isovalent.com/blog/]
- A Chinese blog that elaborates how to install & deploy k8s related services. [https://tinychen.com/tags/cilium/]
- A observability demo with good UI. [https://github.com/isovalent/cilium-grafana-observability-demo]


