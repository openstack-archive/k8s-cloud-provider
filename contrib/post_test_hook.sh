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
    'Basic StatefulSet functionality [StatefulSetBasic] should allow template updates'
    'Basic StatefulSet functionality [StatefulSetBasic] should provide basic identity'
    'ConfigMap [AfterEach] updates should be reflected in volume [Conformance] [Volume]'
    'ConfigMap should be consumable from pods in volume with mappings [Conformance] [Volume]'
    'ConfigMap should be consumable from pods in volume with mappings and Item mode set[Conformance] [Volume]'
    'ConfigMap should be consumable from pods in volume with mappings as non-root [Conformance] [Volume]'
    'ConfigMap should be consumable in multiple volumes in the same pod [Conformance] [Volume]'
    'DNS should provide DNS for ExternalName services'
    'DNS should provide DNS for pods for Hostname and Subdomain Annotation'
    'DNS should provide DNS for services [Conformance]'
    'DNS should provide DNS for the cluster [Conformance]'
    'Deployment RecreateDeployment should delete old pods and create new ones'
    'Deployment [AfterEach] deployment should support rollover'
    'Deployment [It] deployment should support rollover'
    'Deployment paused deployment should be ignored by the controller'
    'DisruptionController [It] evictions: enough pods, absolute => should allow an eviction'
    'DisruptionController [It] evictions: enough pods, replicaSet, percentage => should allow an eviction'
    'DisruptionController evictions: too few pods, absolute => should not allow an eviction'
    'Downward API volume [AfterEach] should set DefaultMode on files [Conformance] [Volume]'
    'Downward API volume should provide container.*s cpu limit [Conformance] [Volume]'
    'Downward API volume should set mode on item file [Conformance] [Volume]'
    'Downward API volume should update labels on modification [Conformance] [Volume]'
    'EmptyDir volumes should support (non-root,0666,default) [Conformance] [Volume]'
    'EmptyDir volumes should support (root,0666,default) [Conformance] [Volume]'
    'Garbage collector [It] should orphan pods created by rc if deleteOptions.OrphanDependents is nil'
    'Granular Checks: Pods should function for node-pod communication: udp [Conformance]'
    'Guestbook application should create and stop a working application [Conformance]'
    'HostPath [AfterEach] should support subPath [Volume]'
    'InitContainer should not start app containers if init containers fail on a RestartAlways pod'
    'Kubectl client [AfterEach] [k8s.io] Kubectl run rc should create an rc from an image [Conformance]'
    'Kubectl client [k8s.io] Kubectl label [BeforeEach] should update the label on a resource [Conformance]'
    'Kubectl client [k8s.io] Simple pod [It] should return command exit codes'
    'Kubectl client [k8s.io] Simple pod should handle in-cluster config'
    'Kubectl client [k8s.io] Simple pod should support exec through an HTTP proxy'
    'Kubernetes Dashboard should check that the kubernetes-dashboard instance is alive'
    'LimitRange [AfterEach] should create a LimitRange with defaults and ensure pod has those defaults applied.'
    'NFS should be mountable'
    'NFSv3 should be mountable for NFSv3 [Volume]'
    'NFSv4 should be mountable for NFSv4 [Volume]'
    'Pods Extended [AfterEach] [k8s.io] Pods Set QOS Class should be submitted and removed [Conformance]'
    'Pods [AfterEach] should support retrieving logs from the container over websockets'
    'Pods should support remote command execution over websockets'
    'Port forwarding [k8s.io] With a server listening on 0.0.0.0 [k8s.io] that expects a client request [It] should support a client that connects, sends data, and disconnects'
    'Port forwarding [k8s.io] With a server listening on 0.0.0.0 [k8s.io] that expects no client request should support a client that connects, sends data, and disconnects'
    'Port forwarding [k8s.io] With a server listening on localhost [k8s.io] that expects a client request [It] should support a client that connects, sends data, and disconnects [Conformance]'
    'Port forwarding [k8s.io] With a server listening on localhost [k8s.io] that expects no client request should support a client that connects, sends data, and disconnects [Conformance]'
    'PreStop should call prestop when killing a pod [Conformance]'
    'PrivilegedPod should enable privileged commands'
    'Probing container should be restarted with a /healthz http liveness probe [Conformance]'
    'Projected [AfterEach] should be consumable in multiple volumes in the same pod [Conformance] [Volume]'
    'Projected [It] updates should be reflected in volume [Conformance] [Volume]'
    'Projected should be consumable from pods in volume with mappings [Conformance] [Volume]'
    'Projected should be consumable from pods in volume with mappings and Item Mode set [Conformance] [Volume]'
    'Projected should be consumable from pods in volume with mappings and Item mode set[Conformance] [Volume]'
    'Projected should be consumable from pods in volume with mappings as non-root [Conformance] [Volume]'
    'Projected should provide container.*s cpu limit [Conformance] [Volume]'
    'Projected should set DefaultMode on files [Conformance] [Volume]'
    'Projected should set mode on item file [Conformance] [Volume]'
    'Projected should update labels on modification [Conformance] [Volume]'
    'Proxy version v1 [AfterEach] should proxy logs on node with explicit kubelet port [Conformance]'
    'ReplicaSet should serve a basic image on each replica with a public image [Conformance]'
    'ReplicationController [It] should serve a basic image on each replica with a public image [Conformance]'
    'ResourceQuota [AfterEach] should create a ResourceQuota and ensure its status is promptly calculated.'
    'ResourceQuota [It] should create a ResourceQuota and capture the life of a configMap.'
    'ResourceQuota should create a ResourceQuota and capture the life of a secret.'
    'Secrets optional updates should be reflected in volume [Conformance] [Volume]'
    'Secrets should be consumable from pods in volume with mappings [Conformance] [Volume]'
    'Secrets should be consumable from pods in volume with mappings and Item Mode set [Conformance] [Volume]'
    'Services [It] should be able to create a functioning NodePort service'
    'Services should create endpoints for unready pods'
    'Services should serve a basic endpoint from pods [Conformance]'
    'StatefulSet [k8s.io] Basic StatefulSet functionality [StatefulSetBasic] should adopt matching orphans and release non-matching pods'
    'StatefulSet [k8s.io] Basic StatefulSet functionality [StatefulSetBasic] should not deadlock when a pod.*s predecessor fails'
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