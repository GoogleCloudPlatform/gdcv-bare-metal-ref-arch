#!/usr/bin/env bash

# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

source ${ABM_WORK_DIR}/scripts/helpers/include.sh

export KUBECONFIG=$(ls -1 ${ABM_WORK_DIR}/bmctl-workspace/*/*-kubeconfig | tr '\n' ':')
for cluster_num in $(seq 1 $NUM_CLUSTERS); do
    cluster_name=${CLUSTER_NAME["$cluster_num"]}
    
    title_no_wait "Deploying application on ${cluster_name}"
    print_and_execute "kubectl --context=${cluster_name} label namespace ${APP_NAMESPACE} istio.io/rev=${ASM_REVISION} --overwrite"
    print_and_execute "kubectl --context=${cluster_name} --namespace=${APP_NAMESPACE} apply -f ${ABM_WORK_DIR}/bank-of-anthos/extras/jwt/jwt-secret.yaml"
    print_and_execute "kubectl --context=${cluster_name} --namespace=${APP_NAMESPACE} apply -f ${ABM_WORK_DIR}/bank-of-anthos/kubernetes-manifests"
    echo
done

check_local_error
total_runtime
exit ${local_error}
