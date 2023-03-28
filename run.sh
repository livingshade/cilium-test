set +ex

suffix=$1
kubectl delete -f ./k8s/bookinfo/bookinfo-v1.yaml

sleep 30

kubectl apply -f ./k8s/bookinfo/bookinfo-v1.yaml

sleep 30

rm -f result.csv

echo "mean(us),stddev(us),p50(us),p90(us),p99(us),dur(us),#req,data(byte)" >> result.csv

for i in 1 2 3 4 5 6 7 8 9 10
do
    echo "running $i th time"
    sleep 1
    ./wrk/wrk -t1 -c1 -d 60s http://10.96.88.88:9080 -L -s ./lua/gen.lua
    sleep 5
done

timestamp=$(date '+%Y-%m-%d+%H:%M:%S')

mkdir -p result

echo "move result to ./result/${timestamp}.${suffix}.csv"
mv "result.csv" "./result/${timestamp}.${suffix}.csv"

set -ex