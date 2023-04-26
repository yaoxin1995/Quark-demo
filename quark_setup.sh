#!/bin/bash

# This script is used to set up compilation enviroment for confidential quark

function setup_compilation_env_for_quark {
    rustup toolchain install nightly-2022-08-11-x86_64-unknown-linux-gnu
    rustup default nightly-2022-08-11-x86_64-unknown-linux-gnu
    cargo install cargo-xbuild
    sudo apt-get install libcap-dev
    sudo apt-get install build-essential cmake gcc libudev-dev libnl-3-dev libnl-route-3-dev ninja-build pkg-config valgrind python3-dev cython3 python3-docutils pandoc libclang-dev
    rustup component add rust-src
    sudo mkdir /var/log/quark

    cat <<EOF | sudo tee /etc/containerd/config.toml
version = 2
[plugins."io.containerd.runtime.v1.linux"]
  shim_debug = true
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  runtime_type = "io.containerd.runc.v2"
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc]
  runtime_type = "io.containerd.runsc.v1"
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.quark]
  runtime_type = "io.containerd.quark.v1"
EOF
}

function compile_quark {
    setup_compilation_env_for_quark

    push master-thesis-quark 

    make clean
    make
    make install

    pop
}

function compile_kbs {
    push kbs

    wget https://go.dev/dl/go1.20.1.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.20.1.linux-amd64.tar.gz
    export PATH="/usr/local/go/bin:${PATH}"
    make kbs

    push secret

    sudo chmod +7 install_secrets.sh
    exec ./install_secrets.sh

    pop

    pop
}

function compile_secure_client {
    push Trusted_Client

    cargo build

    pop
}

compile_quark

compile_kbs

compile_secure_client