#!/bin/bash

set -ex

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
#sudo containerd config dump


sudo systemctl daemon-reload
sudo systemctl restart kubelet

sudo rm -rf /etc/cni/net.d

if type cilium >/dev/null 2>&1; then
  cilium uninstall >/dev/null 2>&1
fi

sudo kubeadm reset -f
sudo rm -rf $HOME/.kube

sudo kubeadm init --pod-network-cidr 10.244.0.0/17 # check the output and execute command to setup the cluster

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

if [ $CNI == "flannel" ]
then
echo "use flannel CNI"
. ./scripts/cni_flannel.sh
elif [ $CNI == "cilium" ]
then
echo "use Cilium CNI"
. ./scripts/cni_cilium.sh
fi
### for data plane
# kubeadm join xxx 

# This may not work for kubernetes v1.25+
kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

set +ex