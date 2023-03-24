set -ex

export PROJECT_DIR=$PWD

sudo apt-get update
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release -y


sudo apt-get install htop -y

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null


sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io -y

sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
# sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-get install -y kubelet=1.24.4-00 kubeadm=1.24.4-00 kubectl=1.24.4-00
sudo apt-mark hold kubelet kubeadm kubectl

sudo apt-get install -y linux-tools-common linux-tools-generic linux-tools-`uname -r`
sudo apt-get install -y sysstat
sudo apt install -y python3-pip

sudo apt install -y bison build-essential cmake flex git libedit-dev   libllvm11 llvm-11-dev libclang-11-dev python zlib1g-dev libelf-dev libfl-dev python3-distutils

sudo apt-get install luarocks -y


cd $PROJECT_DIR

if [ -d "$PROJECT_DIR/bcc" ];
then sudo rm -rf $PROJECT_DIR/bcc;
fi
git clone https://github.com/iovisor/bcc.git
mkdir bcc/build; cd bcc/build
cmake ..
make -j $(nproc)
sudo make install
cmake -DPYTHON_CMD=python3 .. # build python3 binding
pushd src/python/
make -j $(nproc)
sudo make install
popd


if [ -d "$PROJECT_DIR/wrk" ];
then sudo rm -rf $PROJECT_DIR/wrk;
fi

cd $PROJECT_DIR
git clone https://github.com/wg/wrk.git
cd wrk
make -j $(nproc)

git clone https://github.com/giltene/wrk2.git
cd wrk2
make -j $(nproc)
cd $PROJECT_DIR

## install helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm


echo "source <(kubectl completion bash)" >> ~/.bashrc # add autocomplete permanently to your bash shell.
echo "alias ku='kubectl'" >> ~/.bashrc  
echo "alias ku='kubectl'" >> ~/.zshrc  

set +ex