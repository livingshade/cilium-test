sudo kubeadm init --skip-phases=addon/kube-proxy

sudo kubeadm join 130.127.133.136:6443 --token azowce.irpv5o0sora05i3g \
        --discovery-token-ca-cert-hash sha256:6c7871492ab88cbc5bd201468b43ead8c796f7254d4052b128dcb98b381ad195