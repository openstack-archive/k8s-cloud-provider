#!/bin/bash -xe

# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

# This script is executed inside post_test_hook function in devstack gate.

BASE_DIR=$(cd $(dirname $BASH_SOURCE)/.. && pwd)


TESTS_LIST_REGEX=(
    '\[Slow\]'
    '\[Serial\]'
    '\[Disruptive\]'
    '\[Flaky\]'
    '\[Feature:.+\]'
    '\[HPA\]'
)

TESTS_LIST=(
    'ConfigMap [AfterEach] updates should be reflected in volume [Conformance] [Volume]'
    'Deployment [AfterEach] deployment should support rollover'
    'Deployment [It] deployment should support rollover'
    'Deployment [It] lack of progress should be reported in the deployment status'
    'DisruptionController [It] evictions: enough pods, absolute => should allow an eviction'
    'DisruptionController [It] evictions: enough pods, replicaSet, percentage => should allow an eviction'
    'Downward API volume [AfterEach] should set DefaultMode on files [Conformance] [Volume]'
    'Downward API volume [It] should provide container cpu request [Conformance] [Volume]'
    'EmptyDir volumes [AfterEach] should support (root,0666,default) [Conformance] [Volume]'
    'EmptyDir volumes [AfterEach] should support (root,0666,tmpfs) [Conformance] [Volume]'
    'EmptyDir volumes [BeforeEach] should support (root,0644,default) [Conformance] [Volume]'
    'Garbage collector [It] should orphan pods created by rc if deleteOptions.OrphanDependents is nil'
    'HostPath [AfterEach] should support subPath [Volume]'
    'Kubectl client [AfterEach] [k8s.io] Kubectl run rc should create an rc from an image [Conformance]'
    'Kubectl client [k8s.io] Kubectl expose [It] should create services for rc [Conformance]'
    'Kubectl client [k8s.io] Kubectl label [BeforeEach] should update the label on a resource [Conformance]'
    'Kubectl client [k8s.io] Simple pod [BeforeEach] should support port-forward'
    'Kubectl client [k8s.io] Simple pod [It] should return command exit codes'
    'Kubectl client [k8s.io] Update Demo [It] should create and stop a replication controller [Conformance]'
    'Kubectl client [k8s.io] Update Demo [It] should do a rolling update of a replication controller [Conformance]'
    'KubeletManagedEtcHosts [It] should test kubelet managed /etc/hosts file [Conformance]'
    'LimitRange [AfterEach] should create a LimitRange with defaults and ensure pod has those defaults applied.'
    'Networking [BeforeEach] [k8s.io] Granular Checks: Pods should function for intra-pod communication: udp [Conformance]'
    'Networking [k8s.io] Granular Checks: Pods [It] should function for intra-pod communication: http [Conformance]'
    'Pods Extended [AfterEach] [k8s.io] Pods Set QOS Class should be submitted and removed [Conformance]'
    'Pods [AfterEach] should get a host IP [Conformance]'
    'Pods [AfterEach] should support retrieving logs from the container over websockets'
    'Pods [It] should allow activeDeadlineSeconds to be updated [Conformance]'
    'Pods [It] should be updated [Conformance]'
    'Port forwarding [k8s.io] With a server listening on 0.0.0.0 [It] should support forwarding over websockets'
    'Port forwarding [k8s.io] With a server listening on 0.0.0.0 [k8s.io] that expects a client request [It] should support a client that connects, sends data, and disconnects'
    'Port forwarding [k8s.io] With a server listening on localhost [k8s.io] that expects a client request [It] should support a client that connects, sends data, and disconnects [Conformance]'
    'Probing container [It] should be restarted with a exec "cat /tmp/health" liveness probe [Conformance]'
    'Projected [AfterEach] should be consumable in multiple volumes in the same pod [Conformance] [Volume]'
    'Projected [It] updates should be reflected in volume [Conformance] [Volume]'
    'Proxy version v1 [AfterEach] should proxy logs on node with explicit kubelet port [Conformance]'
    'ReplicationController [It] should adopt matching pods on creation'
    'ReplicationController [It] should serve a basic image on each replica with a public image [Conformance]'
    'ResourceQuota [AfterEach] should create a ResourceQuota and ensure its status is promptly calculated.'
    'ResourceQuota [It] should create a ResourceQuota and capture the life of a configMap.'
    'Secrets [It] should be consumable from pods in volume [Conformance] [Volume]'
    'Secrets [It] should be consumable from pods in volume as non-root with defaultMode and fsGroup set [Conformance] [Volume]'
    'ServiceAccounts [It] should mount an API token into pods [Conformance]'
    'Services [It] should be able to create a functioning NodePort service'
    'StatefulSet [k8s.io] Basic StatefulSet functionality [StatefulSetBasic] [It] Scaling should happen in predictable order and halt if any stateful pod is unhealthy'
)

function escape_test_name() {
    sed 's/\[[^]]*\]//g' <<< "$1" | sed "s/[^[:alnum:]]/ /g" | tr -s " " | sed "s/^\s\+//" | sed "s/\s/.*/g"
}

function test_names () {
    local first=y
    for name in "${TESTS_LIST_REGEX[@]}"; do
        if [ -z "${first}" ]; then
            echo -n "|"
        else
            first=
        fi
        echo -n "${name}"
    done
    for name in "${TESTS_LIST[@]}"; do
        if [ -z "${first}" ]; then
            echo -n "|"
        else
            first=
        fi
        echo -n "$(escape_test_name "${name}")"
    done
}

cd $BASE/new/devstack
source openrc admin admin

echo "In post_test_hook"

# Get the latest stable version of kubernetes
export K8S_VERSION=$(curl -sS https://storage.googleapis.com/kubernetes-release/release/stable.txt)
echo "K8S_VERSION : ${K8S_VERSION}"

echo "Download Kubernetes CLI"
sudo wget -O kubectl "http://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/linux/amd64/kubectl"
sudo chmod 755 kubectl
./kubectl get nodes

echo "Waiting for kubernetes service to start..."
for i in {1..600}
do
    running_count=$(./kubectl -s=http://127.0.0.1:8080 get svc --no-headers 2>/dev/null | grep "443" | wc -l)
    if [ "$running_count" -ge 1 ]; then
      break
    fi
    echo -n "."
    sleep 1
done

echo "Cluster created!"
echo ""

echo "Dump Kubernetes Objects..."
./kubectl -s=http://127.0.0.1:8080 get componentstatuses
./kubectl -s=http://127.0.0.1:8080 get configmaps
./kubectl -s=http://127.0.0.1:8080 get daemonsets
./kubectl -s=http://127.0.0.1:8080 get deployments
./kubectl -s=http://127.0.0.1:8080 get events
./kubectl -s=http://127.0.0.1:8080 get endpoints
./kubectl -s=http://127.0.0.1:8080 get horizontalpodautoscalers
./kubectl -s=http://127.0.0.1:8080 get ingress
./kubectl -s=http://127.0.0.1:8080 get jobs
./kubectl -s=http://127.0.0.1:8080 get limitranges
./kubectl -s=http://127.0.0.1:8080 get nodes
./kubectl -s=http://127.0.0.1:8080 get namespaces
./kubectl -s=http://127.0.0.1:8080 get pods
./kubectl -s=http://127.0.0.1:8080 get persistentvolumes
./kubectl -s=http://127.0.0.1:8080 get persistentvolumeclaims
./kubectl -s=http://127.0.0.1:8080 get quota
./kubectl -s=http://127.0.0.1:8080 get resourcequotas
./kubectl -s=http://127.0.0.1:8080 get replicasets
./kubectl -s=http://127.0.0.1:8080 get replicationcontrollers
./kubectl -s=http://127.0.0.1:8080 get secrets
./kubectl -s=http://127.0.0.1:8080 get serviceaccounts
./kubectl -s=http://127.0.0.1:8080 get services


echo "Running tests..."
set -ex

export GOPATH=${BASE_DIR}/go
export KUBE_MASTER=local
export KUBECONFIG=/var/run/kubernetes/admin.kubeconfig
export KUBERNETES_PROVIDER=skeleton
export KUBERNETES_CONFORMANCE_TEST=y
export GINKGO_PARALLEL=y
export GINKGO_NO_COLOR=y
export KUBE_MASTER_IP=https://127.0.0.1:6443/

pushd $GOPATH/src/k8s.io/kubernetes >/dev/null
sudo -E PATH=$GOPATH/bin:$PATH make all WHAT=cmd/kubectl
sudo -E PATH=$GOPATH/bin:$PATH make all WHAT=vendor/github.com/onsi/ginkgo/ginkgo

# e2e test does not work with 1.8, so fall back to 1.7
source $DEST/.gimme/envs/go1.7.5.env

sudo -E PATH=$GOPATH/bin:$PATH make all WHAT=test/e2e/e2e.test
sudo -E PATH=$GOPATH/bin:$PATH go run hack/e2e.go -- -v --test --test_args="--ginkgo.trace=true --ginkgo.skip=$(test_names)"
popd >/dev/null