set +ex

cilium hubble disable

kubectl apply -f ./k8s/cilium/bookinfo-v1.yaml

sleep 15

for i in 1 2 3 4 5
do
    echo "running $i time" >> output.txt
    sleep 1
    ./wrk/wrk -t1 -c1 -d 60s http://10.96.88.88:9080 -L -s ./lua/gen.lua >> output.txt
    sleep 5
done

set -ex