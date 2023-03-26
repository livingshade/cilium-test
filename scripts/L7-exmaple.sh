kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/1.13.1/examples/kubernetes/servicemesh/envoy/test-application.yaml

export CLIENT2=$(kubectl get pods -l name=client2 -o jsonpath='{.items[0].metadata.name}')