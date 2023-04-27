# Quark-demo


## 1. Prerequest
### 1.1 Kubernetes cluster with containerd as high level runtime is ready

#### 1.1.1  Kubernetes cluser quick setup:
There are multiple ways to start a k8s cluster. We recommend using kubeadm to start a production k8s cluster. Please check [kubeadm](https://kubernetes.io/docs/reference/setup-tools/kubeadm/) on how to install and use kubeadm.

For kubeadm init and join command, need to set parameter "--cri-socket=/var/run/containerd/containerd.sock".

Following is sample kubeadm command to init a cluster.
```
# Execute on master node
sudo kubeadm init --cri-socket=/var/run/containerd/containerd.sock --pod-network-cidr=10.244.0.0/16

sudo rm $HOME/.kube/config
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Optional, make master node runable for pod:
kubectl taint nodes --all node-role.kubernetes.io/master-
# Starting with 1.20 the command should be: 
kubectl taint node mymasternode  node-role.kubernetes.io/control-plane:NoSchedule-
```

```
# Execute on worker node
# Need to replace token and cert with the real one in the master node. 
# The data can be found in master node's kubeadm init log.
sudo kubeadm join 10.218.233.29:6443 --cri-socket=/var/run/containerd/containerd.sock --token qy2r1j.t0y5ekx71t0tcfiq \
        --discovery-token-ca-cert-hash sha256:78a23762652befd90bbcd3506ca9309c5243371360d7a66fc131cb1a4b255553
```

#### 1.1.2 Add CNI to K8S
Container Network Interface (CNI) provides networking to k8s. Following example use flannel as CNI for test purpose.
```
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```

``For detailed k8s setup, pleasse refer to this`` [doc](https://computingforgeeks.com/deploy-kubernetes-cluster-on-ubuntu-with-kubeadm/)

## 1.2 Rust is installed
```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

## 2.Quark enviroment setup


###  2.1 Clone
```
git clone https://github.com/yaoxin1995/Quark-demo.git
git submodule update --init
```

### 2.2 Build
```
sudo ./quark_setup.sh
```

Note if you got the similar error as following during comilation, please add `#![feature(generic_associated_types)]` to  `/root/.cargo/registry/src/github.com-1ecc6299db9ec823/spki-0.7.0/src/lib.rs`, or other similar location.
```
error[E0658]: generic associated types are unstable
   --> /root/.cargo/registry/src/github.com-1ecc6299db9ec823/spki-0.7.0/src/algorithm.rs:183:9
    |
183 |         type Borrowed<'a> = AlgorithmIdentifierRef<'a>;
    |         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    |
    = note: see issue #44265 <https://github.com/rust-lang/rust/issues/44265> for more information
    = help: add `#![feature(generic_associated_types)]` to the crate attributes to enable

error[E0658]: generic associated types are unstable
   --> /root/.cargo/registry/src/github.com-1ecc6299db9ec823/spki-0.7.0/src/spki.rs:197:9
    |
197 |         type Borrowed<'a> = SubjectPublicKeyInfoRef<'a>;
    |         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    |
    = note: see issue #44265 <https://github.com/rust-lang/rust/issues/44265> for more information
    = help: add `#![feature(generic_associated_types)]` to the crate attributes to enable
```

### 2.3 Install Secret to the location where kbs can find

```
./install_secret.sh
```

### 2.4 Add quark as a Runtime Resource to K8S

```
cat <<EOF | kubectl apply -f -
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: quark
handler: quark
EOF
```

### 2.5 Modify `SECRET_MANAGER_IP` specified in `mongi.yaml` and `syscall_test.yaml`
Normally the SECRET_MANAGER_IP is the IP of your workstation. Enclave uses this ip to communicate with the KBS

In my case, the IP is `10.206.133.76`. By default, KBS is running on port 8000.


### 2.6 Add quark as a Runtime Resource to K8S

```
cat <<EOF | kubectl apply -f -
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: quark
handler: quark
EOF
```







