#!/bin/bash -xe

CONFORMANCE_REPO=${CONFORMANCE_REPO:-github.com/kubernetes/kubernetes}
K8S_SRC=${GOPATH}/src/k8s.io/kubernetes

mkdir -p ${K8S_SRC}
git clone https://${CONFORMANCE_REPO} ${K8S_SRC}

cd ${K8S_SRC}
go get -u github.com/jteeuwen/go-bindata/go-bindata
sudo -E hack/local-up-cluster.sh

