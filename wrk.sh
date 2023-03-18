set -ex



git clone https://github.com/wg/wrk.git
pushd ./wrk
make -j 

git clone https://github.com/giltene/wrk2.git
cd wrk2
make -j 

popd

set +ex