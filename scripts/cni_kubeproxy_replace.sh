set -ex

export API_SERVER_IP=$(cat init_output | grep "kubeadm join" | awk -F'[ :]' '{print $3}')
export API_SERVER_PORT=$(cat init_output | grep "kubeadm join" | awk -F'[ :]' '{print $4}')

echo "set env $API_SERVER_IP::$API_SERVER_PORT"

cat init_output
# if more than one worker.
# kubeadm join 130.127.133.224:6443 --token ... \
# 	--discovery-token-ca-cert-hash sha256:...

# helm repo add cilium https://helm.cilium.io/

# ip should match
helm install cilium cilium/cilium --version 1.13.1 \
    --namespace kube-system \
    --set kubeProxyReplacement=strict \
    --set k8sServiceHost=${API_SERVER_IP} \
    --set k8sServicePort=${API_SERVER_PORT} \
    --set-string extraConfig.enable-envoy-config=true

# kubectl -n kube-system get pods -l k8s-app=cilium
# # expect nodes info

# kubectl -n kube-system exec ds/cilium -- cilium status | grep KubeProxyReplacement
# # expect:
# # KubeProxyReplacement:    Strict  

# kubectl exec -it -n kube-system cilium-zr2pg -- cilium service list
# expect (change cilium pods name):
#ID   Frontend               Service Type   Backend
# [...]
# 4    10.104.239.135:80      ClusterIP      1 => 10.217.0.107:80
#                                            2 => 10.217.0.149:80
# 5    0.0.0.0:31940          NodePort       1 => 10.217.0.107:80
#                                            2 => 10.217.0.149:80
# 6    192.168.178.29:31940   NodePort       1 => 10.217.0.107:80
#                                            2 => 10.217.0.149:80
# 7    172.16.0.29:31940      NodePort       1 => 10.217.0.107:80
set +ex