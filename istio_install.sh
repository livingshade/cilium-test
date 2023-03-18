#!/bin/bash

set -ex



# Install Istio
# Delete if installed
if [ -d "./istio-1.14.1" ];
then sudo rm -rf ./istio-1.14.1;
fi
curl -k -L https://istio.io/downloadIstio | ISTIO_VERSION=1.14.1 sh -
cd istio-1.14.1
sudo cp bin/istioctl /usr/local/bin
istioctl x precheck
istioctl install --set profile=default -y

# turn on auto-injection
kubectl label namespace default istio-injection=enabled --overwrite
# turn off auto-injection
# kubectl label namespace default istio-injection-

set +ex