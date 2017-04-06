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


TESTS_TO_SKIP=(
    '\[Slow\]'
    '\[Serial\]'
    '\[Disruptive\]'
    '\[Flaky\]'
    '\[Feature:.+\]'
    '\[HPA\]'
    'Basic.*StatefulSet.*functionality.*should.*allow.*template.*updates'
    'Dashboard'
    'Granular.*Checks.*Pods.*should.*function.*for.*node\-pod.*communication:.*udp'
    'Guestbook.*application.*should.*create.*and.*stop.*a.*working.*application'
    'NFS.*should.*be.*mountable'
    'RecreateDeployment.*should.*delete.*old.*pods.*and.*create.*new.*ones'
    'Simple.*pod.*should.*handle.*in\-cluster.*config'
    'Simple.*pod.*should.*support.*exec.*through.*an.*HTTP.*proxy'
    'With.*a.*server.*listening.*on.*localhost.*that.*expects.*no.*client.*request.*should.*support.*a.*client.*that.*connects.*sends.*data.*and.*disconnects'
    'evictions:.*too.*few.*pods,.*absolute.*should.*not.*allow.*an.*eviction'
    'optional.*updates.*should.*be.*reflected.*in.*volume'
    'paused.*deployment.*should.*be.*ignored.*by.*the.*controller'
    'should.*be.*consumable.*from.*pods.*in.*volume.*with.*mappings'
    'should.*be.*restarted.*with.*a.*healthz.*http.*liveness.*probe'
    'should.*call.*prestop.*when.*killing.*a.*pod'
    'should.*create.*a.*ResourceQuota.*and.*capture.*the.*life.*of.*a.*secret'
    'should.*create.*endpoints.*for.*unready.*pods'
    'should.*enable.*privileged.*commands'
    'should.*function.*for.*nod\-pod.*communication.*http'
    'should.*not.*start.*app.*containers.*if.*init.*containers.*fail.*on.*a.*RestartAlways.*pod'
    'should.*provide.*DNS.*for.*ExternalName.*services'
    'should.*provide.*DNS.*for.*pods.*for.*Hostname.*and.*Subdomain.*Annotation'
    'should.*provide.*DNS.*for.*services'
    'should.*provide.*DNS.*for.*the.*cluster'
    'should.*provide.*basic.*identity'
    'should.*provide.*container.*s.*cpu.*limit'
    'should.*set.*mode.*on.*item.*file'
    'should.*support.*non-root.*0666.*default'
    'should.*support.*remote.*command.*execution.*over.*websockets'
 )

function skipped_test_names () {
    local first=y
    for name in "${TESTS_TO_SKIP[@]}"; do
        if [ -z "${first}" ]; then
            echo -n "|"
        else
            first=
        fi
        echo -n "${name}"
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
sudo -E PATH=$GOPATH/bin:$PATH go run hack/e2e.go -- -v --test --test_args="--ginkgo.trace=true --ginkgo.skip=$(skipped_test_names)"
popd >/dev/null