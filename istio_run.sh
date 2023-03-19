set +ex

kubectl apply -f ./k8s/istio/bookinfo-v1.yaml
kubectl apply -f ./k8s/istio/bookinfo-gateway.yaml

set -ex