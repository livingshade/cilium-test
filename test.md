## install

First, install k8s, then use `cilium_istio_nstall.sh` or `istio_install.sh` to install them accordingly. You may need to install the dependency first.

You should replace the ip address of productpage when testing:

`./wrk/wrk -t1 -c1 -d 10s http://10.104.61.154:9080 -L -s ./lua/gen.lua`



### test Cilium with Istio

```shell

for service in productpage-service productpage-v1 details-v1 reviews-v1; do \
      kubectl apply -f ./k8s/cilium/bookinfo-${service}.yaml ; done

kubectl apply -f ./k8s/cilium/bookinfo-gateway.yaml

```

Running 10s test @ http://10.103.192.222:9080
  1 threads and 1 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    31.92ms   18.66ms  71.14ms   72.78%
    Req/Sec    31.30      5.97    50.00     78.00%
  Latency Distribution
     50%   20.85ms
     75%   60.71ms
     90%   62.74ms
     99%   63.65ms
  313 requests in 10.01s, 1.36MB read
Requests/sec:     31.27
Transfer/sec:    138.74KB

Running 10s test @ http://10.103.192.222:9080
  1 threads and 1 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    29.03ms   15.53ms  69.18ms   82.82%
    Req/Sec    35.20      7.85    60.00     84.00%
  Latency Distribution
     50%   20.49ms
     75%   33.13ms
     90%   60.45ms
     99%   64.11ms
  352 requests in 10.00s, 1.53MB read
Requests/sec:     35.18
Transfer/sec:    156.09KB

Running 10s test @ http://10.103.192.222:9080
  1 threads and 1 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    28.02ms   15.60ms  64.98ms   83.18%
    Req/Sec    37.10      9.88    60.00     80.00%
  Latency Distribution
     50%   19.52ms
     75%   33.29ms
     90%   59.75ms
     99%   62.62ms
  371 requests in 10.01s, 1.61MB read
Requests/sec:     37.06

### test Istio

```shell
sudo reboot

bash ./k8s_setup.sh
bash ./istio_install.sh

kubectl apply -f ./k8s/istio/bookinfo-v1.yaml
kubectl apply -f ./k8s/istio/bookinfo-gateway.yaml
kubectl apply -f ./k8s/istio/destination-rule.yaml

./wrk/wrk -t1 -c1 -d 10s http://10.104.61.154:9080 -L -s ./lua/gen.lua

```


```
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    23.13ms   12.43ms  65.81ms   83.37%
    Req/Sec    45.59     12.09    60.00     42.00%
  Latency Distribution
     50%   18.36ms
     75%   19.20ms
     90%   39.38ms
     99%   61.82ms
```