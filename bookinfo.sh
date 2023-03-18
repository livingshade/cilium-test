
for service in productpage-service productpage-v1 details-v1 reviews-v1; do \
      kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/1.13.0/examples/kubernetes-istio/bookinfo-${service}.yaml ; done

kubectl get deployments

kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/1.13.0/examples/kubernetes-istio/bookinfo-gateway.yaml

export NODE_IP=130.127.133.136

export GATEWAY_URL=http://$NODE_IP:$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')

export PRODUCTPAGE_URL=${GATEWAY_URL}/productpage

kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/1.13.0/examples/kubernetes-istio/route-rule-reviews-v1.yaml

for service in ratings-v1 reviews-v2; do \
      kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/1.13.0/examples/kubernetes-istio/bookinfo-${service}.yaml ; done
