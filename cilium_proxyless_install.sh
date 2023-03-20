set -ex

## install helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

. ./config.sh

sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

sudo mkdir -p /etc/docker
sudo mkdir -p ${DOCKER_DATA_ROOT}
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "data-root": "${DOCKER_DATA_ROOT}"
}
EOF

sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker


sudo swapoff -a

sudo rm -f /etc/containerd/config.toml
sudo mkdir -p ${CONTAINERD_ROOT_PATH}
sudo mkdir -p ${CONTAINERD_STATE_PATH} 
cat <<EOF | sudo tee /etc/containerd/config.toml
root = "${CONTAINERD_ROOT_PATH}"
state = "${CONTAINERD_STATE_PATH}"
EOF
sudo systemctl restart containerd
sudo containerd config dump


sudo systemctl daemon-reload
sudo systemctl restart kubelet

sudo kubeadm reset -f
sudo rm -rf $HOME/.kube

sudo kubeadm init --skip-phases=addon/kube-proxy

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


# you don't need to do that if have worker nodes
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
kubectl taint nodes --all node-role.kubernetes.io/master-

# if more than one worker.
# kubeadm join 130.127.133.224:6443 --token ... \
# 	--discovery-token-ca-cert-hash sha256:...

# helm repo add cilium https://helm.cilium.io/

# ip should match
# export API_SERVER_IP="130.127.133.224"
# export API_SERVER_PORT="6443"

helm install cilium cilium/cilium --version 1.13.1 \
    --namespace kube-system \
    --set kubeProxyReplacement=strict \
    --set k8sServiceHost=${API_SERVER_IP} \
    --set k8sServicePort=${API_SERVER_PORT}


kubectl -n kube-system get pods -l k8s-app=cilium
# expect nodes info

kubectl -n kube-system exec ds/cilium -- cilium status | grep KubeProxyReplacement
# expect:
# KubeProxyReplacement:    Strict  

kubectl exec -it -n kube-system cilium-zr2pg -- cilium service list
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