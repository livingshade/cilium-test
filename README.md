# Cilium track

This repo acts as a summary of Cilium documentation.

## Prerequisites  

Run `bash ./scripts/deps.sh` to install the dependency if you are using ubuntu. 

### CNI 

Then run `bash ./scripts/k8s_setup.sh` to set up Kubernetes environments and CNI. You can choose `Cilium` or `Flannel` as CNI by changing the corresponding variables in `config.sh`.

After that, you can use `kubectl get nodes` to see whether all nodes are `READY`. You should check whether coredns is running by `kubectl get pods -n=kube-system`.

You might also use `cilium connectivity test` as sanity check.

## Servicemesh

### Istio with Cilium CNI

>Cilium’s Istio integration allows Cilium to enforce HTTP L7 network policies for mTLS protected traffic within the Istio sidecar proxies. In that sense, Cilium replace the CNI and possbily observability that originally using by Istio, but still keeps the Istio's powerful L7 traffic management features. [Full document here](https://docs.cilium.io/en/stable/network/istio/).

Run `bash ./scripts/cilium_istio_install.sh` do achieve that. 

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

Note that you need to run `k8s_setup.sh` each time when you tries to change the CNI, you may refer to that script for more detail.

## Example

We use bookinfo application to show the functionality and performance. To deploy the application:

```bash
kubectl apply -f ./k8s/bookinfo/bookinfo-v1.yaml

./wrk/wrk -t1 -c1 -d 10s http://10.96.88.88:9080 -L -s ./lua/gen.lua
```

To get experiment data, run `bash ./run.sh <suffix>`, the result will be saved to `./result/<data>.<suffix>.csv`.

### Raw Performance

With no network policy enforced, we have the following results(averaged in 5 run). 


|  | Avg(ms) | Stddev(ms) |
| --- | --- | --- |
| Flannel CNI only | 14.00 | 9.43 |
| Cilium CNI only | 13.99 | 1.15 |
| Cilium + Hubble(L4) | 13.49 | 1.42 |
| Cilium + Istio | 24.47 | 13.76 |
| Flannel + Istio | 24.93 | 14.68 |


`CNI only` means that we only deploy the CNI without the control plane.

`Cilium + Hubble(L4)` means that we use Cilium as CNI and enable the Hubble observability for L3/L4 traffic. Note that the results is similar with CNI only, that is probably because the metrics is passed to Hubble asynchornously, i.e. the observability is not in the critical path, so that the latency is not affected.

`a + b` means that we use `a` as CNI and `b` as control plane.

To reproduce the result, you should deploy each setting, and use `bash ./run.sh`.

## Functionalites


### Network Policies

>Identity-Based: Connectivity policies between endpoints (Layer 3), e.g. any endpoint with label role=frontend can connect to any endpoint with label role=backend.

>Restriction of accessible ports (Layer 4) for both incoming and outgoing connections, e.g. endpoint with label role=frontend can only make outgoing connections on port 443 (https) and endpoint role=backend can only accept connections on port 443 (https).

>Fine grained access control on application protocol level to secure HTTP and remote procedure call (RPC) protocols, e.g the endpoint with label role=frontend can only perform the REST API call GET /userdata/[0-9]+, all other API interactions with role=backend are restricted.

Cilium provides network policies, or more precisely, "passive access control".

You can control whether and how an endpoint(pod/app) can access another endpoint, refer to the [offical documents](https://docs.cilium.io/en/stable/security/policy/language/#id1) for detailed examples.


### Traffic Management

#### North-South 

For ingress and egress traffic, Cilium supports Gateway API.

#### East-West

For communication between microservices, an CiliumEnvoyConfig CRD is required, which means that there is no service mesh level abstraction, and one need to write Envoy config by oneself.

[This blog](https://www.solo.io/blog/cilium-service-mesh-in-action/) implemented a traffic splitting mechanism in Cilium.

### Other Features

There are some features that mentioned in blog but I have not yet found related documents.

## Reference

- Cilium [https://cilium.io/] and its Slack channel.
- Isovalent. There are many blogs that clearly illustrate the architecture about the service mesh. It helps build a high level understanding about Cilium, but somehow lacks codes and toturials. [https://isovalent.com/blog/]
- A Chinese blog that elaborates how to install & deploy k8s related services. [https://tinychen.com/tags/cilium/]
- A observability demo with good UI. [https://github.com/isovalent/cilium-grafana-observability-demo]


