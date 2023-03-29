# Cilium

This repo acts as a brief summary, and some reproduce efforts, of Cilium documentation.

## Prerequisites  

Run `bash ./scripts/deps.sh` to install the dependency. The script is only tested in Ubuntu 20.04.

### CNI 

Run `bash ./scripts/k8s_setup.sh` to set up Kubernetes environments and CNI. You can choose `Cilium` or `Flannel` or `Cilium kubeproxy replacement` as CNI, by changing the variable in `config.sh`. `Cilium kubeproxy replacement` is used to set kubeproxy-fre Cilium servicemesh.

After that, you can use `kubectl get nodes` to see whether all nodes are `READY`. You should check whether coredns service is running by `kubectl get pods -n=kube-system`. You might also use `cilium connectivity test` as sanity check.

## Servicemesh

### Istio control plane

Run `./scripts/istio_install.sh` to install Istio.

### Cilium control plane

Cilium can act as CNI, as well as control plane. For some reasons, the default installation of Cilium only allow you to specify L3/L4 network policies and observability.

#### kubeproxy-free

To enforce L7 related functionalities, you must use `Cilium kubeproxy replacement` when running `k8s_setup.sh`.

> Functionality like L7 policies achieved by Enovy CRD, requires that `kube-proxy` is fully replaced by Cilium. In that case, the installation is quite differenet. [Full document here](https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/)

After installation, run the following scripts as sanity check.

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

With Cilium is installed, use `bash ./scripts/hubble.sh` to enable hubble and access its fancy UI. [More details here](https://docs.cilium.io/en/stable/gettingstarted/hubble/)

By default, L7 traffic is not monitored. Refer to Observability section to enable L7 visibility.

### Istio with Cilium integration

>Cilium’s Istio integration allows Cilium to enforce HTTP L7 network policies for mTLS protected traffic within the Istio sidecar proxies. In that sense, Cilium replace the CNI and possbily observability that originally using by Istio, but still keeps the Istio's powerful L7 traffic management features. [Full document here](https://docs.cilium.io/en/stable/network/istio/).

Run `bash ./scripts/cilium_istio_install.sh` to use that feature. In that way, there will be no sidecar in each pod. Use normal Istio control plane unless you deliberately want  those features.

### Cleanup

I believe the best way is `sudo reboot`. 😄 

After reboot, run `k8s_setup.sh` again, you may refer to the comments in that script for details.

## Example

We use bookinfo application to evaluate the functionality and performance. To deploy the application:

```bash
kubectl apply -f ./k8s/bookinfo/bookinfo-v1.yaml
# run lua scripts to ensure bookinfo services are accessable.
./wrk/wrk -t1 -c1 -d 10s http://10.96.88.88:9080 -L -s ./lua/gen.lua
```

### Raw Performance

With no network policy enforced, we have the following results(averaged from 5 run). 

<!-- |  | Avg(ms) | Stddev(ms) |
| --- | --- | --- |
| Flannel CNI only | 14.00 | 9.43 |
| Cilium CNI only | 13.99 | 1.15 |
| Cilium + Hubble(L4) | 13.49 | 1.42 |
| Cilium + Istio | 24.47 | 13.76 |
| Flannel + Istio | 24.93 | 14.68 | -->

| | Cilium CNI only | Cilium CNI + Istio | Cilium CNI + CTL(L4) |
| --- | --- | --- | --- | 
| Average Latency(ms) | 12.67 | 19.95 | 12.74 | 
| Stddev(ms) | 0.39 | 12.53 | 0.45 | 

`CNI only` means that we only deploy the CNI without the control plane.

`Cilium + Hubble(L4)` means that we use Cilium as CNI and enable the Hubble observability for L3/L4 traffic. Note that the results is similar with CNI only, that is probably because the metrics is passed to Hubble asynchornously, i.e. the observability is not in the critical path, so that the latency is not affected.

`a + b` means that we use `a` as CNI and `b` as control plane.

To reproduce the result, you should deploy each setting, and invoke `bash ./run.sh`.

## Functionalites

### Network Policies

>Identity-Based: Connectivity policies between endpoints (Layer 3), e.g. any endpoint with label role=frontend can connect to any endpoint with label role=backend.

>Restriction of accessible ports (Layer 4) for both incoming and outgoing connections, e.g. endpoint with label role=frontend can only make outgoing connections on port 443 (https) and endpoint role=backend can only accept connections on port 443 (https).

>Fine grained access control on application protocol level to secure HTTP and remote procedure call (RPC) protocols, e.g the endpoint with label role=frontend can only perform the REST API call GET /userdata/[0-9]+, all other API interactions with role=backend are restricted.

Cilium provides network policies. From my understanding, those policies are actually "passive access control". that allow/disallow certain endpoints to communicate with other endpoint, and how. For various policies, refer [offical documents](https://docs.cilium.io/en/stable/security/policy/language/#id1) and [starwar demo](https://docs.cilium.io/en/stable/gettingstarted/demo/).

### Traffic Management

Here is an incomplete list for L7 traffic management features. `supported` means that the feature is natively supported, `require CRD` means that an Envoy config is needed. 

| Features | Ingress/Egress | In Cluster |
| --- | --- | --- |
| Request Routing |  supported | require CRD |
| Fault Injection |  N/A | require CRD |
| TLS Termination |       supported      | N/A|
| Traffic Transformation | supported | require CRD |
| Circuit Breaking | N/A | require CRD |
| Header Modification | supported | require CRD|

#### North-South 

For ingress and egress traffic, Cilium supports Gateway API.

Refer to [this tutorial](https://isovalent.com/blog/post/tutorial-getting-started-with-the-cilium-gateway-api/) for examples.

#### East-West

For communication between microservices, an CiliumEnvoyConfig CRD is required, which means that there is no service mesh level abstraction, and one need to write Envoy config by oneself.

[This blog](https://www.solo.io/blog/cilium-service-mesh-in-action/) implemented a traffic splitting mechanism in Cilium.

As such, Cilium's configs are almost surely more complex and difficult to write, you can refer to `./k8s/L7` for some examples and compare the differences.



### Observability

#### L3/L4

If Hubble ui is enabled, open a browser at `localhost::12000` and invoke `run.sh`, you will see the graph of flows.

You can also use `hubble observe` for a TCP-dump like output.

#### L7

To get L7 visiblity, the kubeproxy must be replaced beforehead.

One way is to enforce L7 policy. Refer to [this example](https://docs.cilium.io/en/stable/network/servicemesh/envoy-traffic-management/#start-observing-traffic-with-hubble) for detail. [I have successfully reproduced this example]

> but this requires the full policy for each selected endpoint to be written. To get more visibility into the application without configuring a full policy, Cilium provides a means of prescribing visibility via annotations when running in tandem with Kubernetes. Refer to [this](https://docs.cilium.io/en/stable/observability/visibility/) for details. [I have not been able to reproduce this example]

For more advanced data-collecting and metrics, you should refer to [this demo](https://github.com/isovalent/cilium-grafana-observability-demo). [I have successfully reproduced this example]

It should be noted that currently an Envoy is required to get L7 visibility, however, the eBPF-based HTTP visibility is possbile, and in fact available  in Isovalent Cilium Enterprise.

### Other Features

There are some features that mentioned in blog but I have not tried yet. I will list the feature and the source.

- Security
    - [Transparent Encryption with IPsec and WireGuard](https://isovalent.com/blog/post/tutorial-transparent-encryption-with-ipsec-and-wireguard/)
    - [Tetragon](https://isovalent.com/blog/post/2022-05-16-tetragon/)
    - [Mutual Authentication](https://isovalent.com/blog/post/2022-05-03-servicemesh-security/)
- TCP
    - [TCP Congestion Control and BBR](https://isovalent.com/blog/post/accelerate-network-performance-with-cilium-bbr/)
    - [Bandwith Manager](https://isovalent.com/blog/post/addressing-bandwidth-exhaustion-with-cilium-bandwidth-manager/)
- [Azure CNI](https://isovalent.com/blog/post/tutorial-azure-cni-powered-by-cilium/)

## Reference

- Cilium [https://cilium.io/] and its Slack channel.
- Isovalent. There are many blogs that clearly illustrate the architecture about the service mesh. It helps build a high level understanding about Cilium, but somehow lacks codes and toturials. [https://isovalent.com/blog/]
- A Chinese blog that elaborates how to install & deploy k8s related services. [https://tinychen.com/tags/cilium/]
- A observability demo with good UI. [https://github.com/isovalent/cilium-grafana-observability-demo]
- Cilium Code Walkthrough [https://arthurchiao.art/blog/cilium-code-series/]

