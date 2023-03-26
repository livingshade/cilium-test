# Cilium track

This repo acts as a brief summary, and some reproduce efforts, of Cilium documentation.

## Prerequisites  

Run `bash ./scripts/deps.sh` to install the dependency. The script is only tested in Ubuntu 20.04.

### CNI 

Then run `bash ./scripts/k8s_setup.sh` to set up Kubernetes environments and CNI. You can choose `Cilium` or `Flannel` or `Cilium kubeproxy replacement` as CNI, by changing the corresponding variable in `config.sh`. For `Cilium kubeproxy replacement`, refer to section kubeproxy-free for detail.

After that, you can use `kubectl get nodes` to see whether all nodes are `READY`. You should check whether coredns service is running by `kubectl get pods -n=kube-system`.

You might also use `cilium connectivity test` as sanity check.

## Servicemesh

### Istio control plane

Run `bash ./scripts/istio_install.sh`.

### Cilium control plane

Cilium can act as CNI, as well as control plane. For some reasons, the default installation of Cilium only allow you to specify L3/L4 network policies and observability. 

#### kubeproxy-free

To enforce L7 related functionalities, you must use `Cilium kubeproxy replacement` when running `k8s_setup.sh`

> Functionality like L7 policies achieved by Enovy CRD, requires that `kube-proxy` is fully replaced by Cilium. In that case, the installation is quite differenet. [Full document here](https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/)

After installation, run the following scripts to ensure that `kubeproxy` is indeed replaced.

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

By default, L7 traffic is not monitored. To enable that, refer to Observability section.

### Istio with Cilium integration

>Cilium’s Istio integration allows Cilium to enforce HTTP L7 network policies for mTLS protected traffic within the Istio sidecar proxies. In that sense, Cilium replace the CNI and possbily observability that originally using by Istio, but still keeps the Istio's powerful L7 traffic management features. [Full document here](https://docs.cilium.io/en/stable/network/istio/).

Run `bash ./scripts/cilium_istio_install.sh`. 

Note that if you should use only use this script when you want to Cilium to enforce L7 policy and using Istio as control plane at the same time.


### Cleanup

I believe the best way is `sudo reboot`. 😄 

Note that you need to run `k8s_setup.sh` each time when changing the CNI, you may refer to the comments in that script for details.

## Example

We use bookinfo application to show the functionality and performance. To deploy the application:

```bash
kubectl apply -f ./k8s/bookinfo/bookinfo-v1.yaml

./wrk/wrk -t1 -c1 -d 10s http://10.96.88.88:9080 -L -s ./lua/gen.lua
```

To reproduce, run `bash ./run.sh <suffix>` and the result will be saved to `./result/<data>.<suffix>.csv`.

### Raw Performance

With no network policy enforced, we have the following results(averaged from 5 run). 

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

However, I must point out that the configuration is much more complex than that of Istio. 

You can refer to `./k8s/L7` for some yaml config example, and compare the differnce. 

### Observability

#### L3/L4

If Hubble ui is enabled, open a browser at `localhost::12000` and invoke `run.sh`, you will see the graph of flows.

You can also use `hubble observe` for a TCP-dump like output.

#### L7

To get L7 visiblity, the kubeproxy must be replaced beforehead.

One way is to enforce L7 policy. Refer to [this example](https://docs.cilium.io/en/stable/network/servicemesh/envoy-traffic-management/#start-observing-traffic-with-hubble) for detail. [I have successfully reproduced this example]

> but this requires the full policy for each selected endpoint to be written. To get more visibility into the application without configuring a full policy, Cilium provides a means of prescribing visibility via annotations when running in tandem with Kubernetes. Refer to [this](https://docs.cilium.io/en/stable/observability/visibility/) for details. [I have not been able to reproduce this example]

For more advanced data-collecting and metrics, you should refer to [this demo](https://github.com/isovalent/cilium-grafana-observability-demo). [I have successfully reproduced this example]


### Other Features

There are some features that mentioned in blog but I have not yet found related documents. I will list the feature and the source.

## Reference

- Cilium [https://cilium.io/] and its Slack channel.
- Isovalent. There are many blogs that clearly illustrate the architecture about the service mesh. It helps build a high level understanding about Cilium, but somehow lacks codes and toturials. [https://isovalent.com/blog/]
- A Chinese blog that elaborates how to install & deploy k8s related services. [https://tinychen.com/tags/cilium/]
- A observability demo with good UI. [https://github.com/isovalent/cilium-grafana-observability-demo]


