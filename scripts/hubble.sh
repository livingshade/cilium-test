cilium hubble enable --ui

cilium status --wait

export HUBBLE_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt)
HUBBLE_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then HUBBLE_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/hubble/releases/download/$HUBBLE_VERSION/hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}
sha256sum --check hubble-linux-${HUBBLE_ARCH}.tar.gz.sha256sum
sudo tar xzvfC hubble-linux-${HUBBLE_ARCH}.tar.gz /usr/local/bin
rm hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}


# kubectl annotate pod reviews-v1-777df99c6d-98m2z policy.cilium.io/proxy-visibility="<Ingress/9080/TCP/HTTP>,<Egress/9080/TCP/HTTP>"

# kubectl annotate pod productpage-v1-66756cddfd-vrhcb policy.cilium.io/proxy-visibility="<Ingress/9080/TCP/HTTP>,<Egress/9080/TCP/HTTP>"
#cilium hubble ui