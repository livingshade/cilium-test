
#Install the Cilium CLI
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/master/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

#Install Cilium
cilium install
cilium status --wait

# expect something like this
#    /¯¯\
# /¯¯\__/¯¯\    Cilium:         OK
# \__/¯¯\__/    Operator:       OK
# /¯¯\__/¯¯\    Hubble:         disabled
# \__/¯¯\__/    ClusterMesh:    disabled
#    \__/

# DaemonSet         cilium             Desired: 2, Ready: 2/2, Available: 2/2
# Deployment        cilium-operator    Desired: 2, Ready: 2/2, Available: 2/2
# Containers:       cilium-operator    Running: 2
#                   cilium             Running: 2
# Image versions    cilium             quay.io/cilium/cilium:v1.9.5: 2
#                   cilium-operator    quay.io/cilium/operator-generic:v1.9.5: 2

cilium connectivity test

# expect
# ...
# ✅ x/x tests successful (0 warnings)