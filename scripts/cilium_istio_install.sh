curl -L https://github.com/cilium/istio/releases/download/1.10.6-1/cilium-istioctl-1.10.6-1-linux-amd64.tar.gz | tar xz

./cilium-istioctl install -y

kubectl label namespace default istio-injection=enabled
