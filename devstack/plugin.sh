#!/bin/bash
#
# lib/dlm
#
# Functions to control the installation and configuration of kubernetes with the
# external OpenStack cloud provider enabled.

# Dependencies:
#
# - ``functions`` file

# ``stack.sh`` calls the entry points in this order:
#
# - install_k8s_cloud_provider
# - configure_k8s_cloud_provider
# - cleanup_dlm

# Save trace setting
_XTRACE_K8S_PROVIDER=$(set +o | grep xtrace)
set +o xtrace


BASE_DIR=$(cd $(dirname $BASH_SOURCE)/.. && pwd)

# Defaults
# --------

CONFORMANCE_REPO=${CONFORMANCE_REPO:-github.com/kubernetes/kubernetes}
K8S_SRC=${GOPATH}/src/k8s.io/kubernetes
ETCD_VERSION=v3.1.4

function install_prereqs {
   # Install pre-reqs
    $BASE_DIR/tools/install-distro-packages.sh
    $BASE_DIR/tools/test-setup.sh
}

function install_etcd_data_store {

    if [ ! -f "$DEST/etcd/etcd-$ETCD_VERSION-linux-amd64/etcd" ]; then
        echo "Installing etcd server"
        mkdir $DEST/etcd
        wget https://github.com/coreos/etcd/releases/download/$ETCD_VERSION/etcd-$ETCD_VERSION-linux-amd64.tar.gz -O $DEST/etcd/etcd-$ETCD_VERSION-linux-amd64.tar.gz
        tar xzvf $DEST/etcd/etcd-$ETCD_VERSION-linux-amd64.tar.gz -C $DEST/etcd
    fi

    # Clean previous DB data
    rm -rf $DEST/etcd/db.etcd
}

function install_docker {
    # Install docker if needed
    path_to_executable=$(which docker)
    if [ -x "$path_to_executable" ] ; then
        echo "Found Docker installation"
    else
        curl -sSL https://get.docker.io | sudo bash
    fi
    docker --version

    # Get the latest stable version of kubernetes
    export K8S_VERSION=$(curl -sS https://storage.googleapis.com/kubernetes-release/release/stable.txt)
    echo "K8S_VERSION : ${K8S_VERSION}"

    echo "Starting docker service"
    sudo systemctl enable docker.service
    sudo systemctl start docker.service --ignore-dependencies
    echo "Checking docker service"
    sudo docker ps
}

function install_k8s_cloud_provider {
    echo_summary "Installing Devstack Plugin for k8s-cloud-provider"

    # Get Kubernetes from source
    mkdir -p ${K8S_SRC}
    git clone https://${CONFORMANCE_REPO} ${K8S_SRC}
    go get -u github.com/jteeuwen/go-bindata/go-bindata

    # Run the script that builds kubernetes from source and starts the processes
    pushd ${K8S_SRC} >/dev/null
    run_process etcd-server "$DEST/etcd/etcd-$ETCD_VERSION-linux-amd64/etcd --data-dir $DEST/etcd/db.etcd"
    run_process kubernetes "hack/local-up-cluster.sh"
    popd >/dev/null
}

# cleanup_k8s_cloud_provider() - Remove residual data files, anything left over from previous
# runs that a clean run would need to clean up
function cleanup_k8s_cloud_provider {
    echo_summary "Cleaning up Devstack Plugin for k8s-cloud-provider"
    sudo rm -rf "$K8S_SRC"
    sudo rm -rf "$DEST/etcd"
}

function stop_k8s_cloud_provider {
    echo_summary "Stop Devstack Plugin for k8s-cloud-provider"
    stop_process kubernetes
    stop_process etcd-server
}

# check for service enabled
if is_service_enabled zun-ui; then

    if [[ "$1" == "stack" && "$2" == "pre-install"  ]]; then
        install_prereqs
        install_etcd_data_store
        install_docker

    elif [[ "$1" == "stack" && "$2" == "install"  ]]; then
        # no-op
        :

    elif [[ "$1" == "stack" && "$2" == "post-config"  ]]; then
        install_k8s_cloud_provider

    elif [[ "$1" == "stack" && "$2" == "extra"  ]]; then
        # no-op
        :
    fi

    if [[ "$1" == "unstack"  ]]; then
        stop_k8s_cloud_provider
    fi

    if [[ "$1" == "clean"  ]]; then
        cleanup_k8s_cloud_provider
    fi
fi

# Restore xtrace
$_XTRACE_K8S_PROVIDER

# Tell emacs to use shell-script-mode
## Local variables:
## mode: shell-script
## End:
