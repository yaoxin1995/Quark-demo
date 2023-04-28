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
cd Quark-demo
git submodule update --init --recursive --remote
git submodule update --init
```

### 2.2 Build
```
sudo ./quark_setup.sh
```

Note if you got a similar error as the following during comilation, this error is caused by tje mismatch between nightly rust compiler and subdepedency requred by quark, so  please add `#![feature(generic_associated_types)]` to  `/root/.cargo/registry/src/github.com-1ecc6299db9ec823/spki-0.7.0/src/lib.rs`, or other similar location.
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

### 2.5 Modify `SECRET_MANAGER_IP` specified in `mongo.yaml` and `syscall_test.yaml`
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


## 3.Run Programe
### 3.1 Start KBS
```
cd Quark-demo/kbs
sudo ./target/debug/kbs --socket 0.0.0.0:8000 --certificate ./cert.pem --private-key ./nopass.pem --insecure-api
```


### 3.2 Deploy Workload

For now, 2 sample workloads are provided:  `mongodb` and `get_attestation_report_syscall_test`
```
kubectl apply -f mongo.yaml
kubectl apply -f syscall_test.yaml
```

The `default backend shield policy` used by enclave  is stored in `secret/policy`, and deployed to kbs' local storage using script `./install_secret.sh` in step `2.3`

Here is a snapshot of the `default frontend policy` (note, enclave only accept policy in backend format, please use the security client's "prepare-policy" cmd to convert the "front-end shield policy" to a "back-end shield policy"):


```
{
    "enable_policy_updata": true,
    "privileged_user_config" :{
        "enable_terminal": true,
        "enable_single_shot_command_line_mode": true,
        "single_shot_command_line_mode_configs" : {
            "allowed_cmd": ["cat", "ls", "cd", "mkdir"],
            "allowed_dir": ["/var"]
        },
        "exec_result_encryption":true,
        "enable_container_logs_encryption":true
    },

    "unprivileged_user_config" :{
        "enable_terminal": true,
        "enable_single_shot_command_line_mode": true,
        "single_shot_command_line_mode_configs" : {
            "allowed_cmd": ["ls"],
            "allowed_dir": ["/var/log"]
        }
    },

    "privileged_user_key_slice": "a very simple secret key to use!",

    "qkernel_log_config": {
        "enable": true,
        "allowed_max_log_level": "Debug"
    },
    
    "syscall_interceptor_config": {
        "enable": false,
        "mode":  "Global",
        "default_action": "ScmpActErrno",
        "syscalls": [
           "sys_read",
            ...
            "sys_set_mempolicy_home_node",
            "sys_attestation_report",
            "sys_socket_produce",
            "sys_socket_consume",
            "sys_proxy"
          ]
    }
}

```
We will explain the shield policy file in `section 4`
### 3.3 Play with `Secure Client`
Copy `reference frontend policy` to `Quark-demo/Trusted_Client/target/debug/`
```
cd Quark-demo/Trusted_Client/target/debug/
cp ../../reference_policy.json policy.json
```

Test functionality of Secure client
```
yaoxin@yaoxin-MS-7B48:~/Quark-demo/Trusted_Client/target/debug$ ./secure-client 
A fictional versioning CLI

Usage: secure-client <COMMAND>

Commands:
  prepare-policy  Convert the frontend policy to the (backend) policy used by qkernel. Default file path is current dir
  terminal        Allocate a terminal inside a container. This terminal is cross platform runable
  issue-cmd       Issue cmd to a container Example: ./secure-client issue-cmd nginx "ls -t /var"
  get             Get resource from cluster (in default namespace)
  edit            Edit a resource
  delete          Delete a resource
  watch           Watches a Kubernetes Resource for changes continuously
  apply           Apply a configuration to a resource by file name
  logs            Get logs of the first container in Pod, Logs CMD works only if the container log is encrypted
  policy-update   Update Exec policy using secure channel
  help            Print this message or the help of the given subcommand(s)

Options:
  -h, --help  Print help
```




## 4. Enclave Shield Policy explained


### 4.1 enable_policy_updata

This option allows the data owner to decide whether to allow the enclave shield policy to be updated during enclave running

### 4.2 privileged_user_config
```
    "privileged_user_config" :{
        "enable_terminal": true,
        "enable_single_shot_command_line_mode": true,
        "single_shot_command_line_mode_configs" : {
            "allowed_cmd": ["cat", "ls", "cd", "mkdir"],
            "allowed_dir": ["/var"]
        },
        "exec_result_encryption":true,
        "enable_container_logs_encryption":true
    },
```
+ enable_terminal: This option allows the data owner to decide whether to allow the termianl to be allocated using secure client during enclave running
+ enable_single_shot_command_line_mode: This option allows the data owner to decide whether to allow the privileged user to issue single cmd to enclave using secure client
+ single_shot_command_line_mode_configs: the config spcecify what cmds and in which dirs these cmds can be executed by privileged users
+ exec_result_encryption: By default, the result of user issued cmd is return with the help of mutiple untrusted component, like containerd. If this option is enabled, enclave will do encryption and integrity protection for the resutl. 
+ enable_container_logs_encryption: This option allows the data owner to decide whether the container logs should be cryptographically protected
+ 
### 4.3 unprivileged_user_config
The non-privileged user configuration allows the data owner to control the behavior of non-privileged level users. Non-privileged users here refer to cloud operators, cluster administrators, etc. who use kubeclt to interact with pods
```
    "unprivileged_user_config" :{
        "enable_terminal": true,
        "enable_single_shot_command_line_mode": true,
        "single_shot_command_line_mode_configs" : {
            "allowed_cmd": ["ls"],
            "allowed_dir": ["/var/log"]
        }
    },
```
### 4.4 privileged_user_key_slice

This is the shared secret used to establish a secure channel between the secure client and the enclave.

### 4.5 qkernel_log_config

Quark usually prints debugging information of guest（qkernel） and host (qvisor) to the local machine's `/var/log/quark` directory.
This configuration allows the enclave owner to determine what level of debug information the enclave will print.

There are 5 possible value of "DebugLevel" as below. If `Off` is choosen, no guest（qkernel）debug messages will be printed
```
Off,
Error,
Warn,
Info,
Debug,
Trace,
```

### 4.6 syscall_interceptor_config

The syscall_interceptor config allow enclave owner to specify which guest system calls are allowed.

Currently syscall interceptor support 2 mode: 
+ `Global` : the inteceptor works for all system calls 
+ `ContextBased`: the inteceptor works only for the system calls issued by application process

`syscalls` spcecify the allowed systems, Note that `syscalls` LIST cannot not be live updated, because the size of this list exceeds the maximum size of messages that can be transmitted in the secure channel.

```
    "syscall_interceptor_config": {
        "enable": false,
        "mode":  "Global",
        "default_action": "ScmpActErrno",
        "syscalls": [
           "sys_read",
            ...
            "sys_set_mempolicy_home_node",
            "sys_attestation_report",
            "sys_socket_produce",
            "sys_socket_consume",
            "sys_proxy"
          ]
    }
```

# 5. Limitation

Each pod only supports 1 container 





