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

TEMP_DIR=${ABM_WORK_DIR}/tmp
mkdir -p ${TEMP_DIR}

title_no_wait "Setup kubectl ctx"
export KUBECONFIG=$(ls -1 ${ABM_WORK_DIR}/bmctl-workspace/*/*-kubeconfig | tr '\n' ':')
for cluster_num in $(seq 1 $NUM_CLUSTERS); do
    cluster_name=${CLUSTER_NAME["$cluster_num"]}
    
    print_and_execute "kubectl ctx ${cluster_name}=${cluster_name}-admin@${cluster_name}"
done

cd ${ABM_WORK_DIR}
for cluster_num in $(seq 1 $NUM_CLUSTERS); do
    cluster_name=${CLUSTER_NAME["$cluster_num"]}
    
    title_no_wait "Generate token for ${cluster_name}"
    
    cat <<EOF > ${TEMP_DIR}/gcp-reader.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: gcp-reader
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: gcp-reader-view
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view
subjects:
- kind: ServiceAccount
  name: gcp-reader
  namespace: default
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: cloud-console-reader
rules:
- apiGroups: [""]
  resources: ["nodes", "persistentvolumes"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "watch", "list"]
- apiGroups: ["storage.k8s.io"]
  resources: ["storageclasses"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["app.k8s.io"]
  resources: ["applications"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: gcp-reader-cloud-console-reader
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cloud-console-reader
subjects:
- kind: ServiceAccount
  name: gcp-reader
  namespace: default
EOF
    kubectl --context=${cluster_name} apply -f ${ABM_WORK_DIR}/tmp/gcp-reader.yaml
    
    SECRET_NAME=$(kubectl --context=${cluster_name} get serviceaccount gcp-reader -o jsonpath='{$.secrets[0].name}')
    
    echo
    bold_no_wait "${cluster_name} token:"
    kubectl --context=${cluster_name} get secret ${SECRET_NAME} -o jsonpath='{$.data.token}' | base64 --decode ; echo
done

echo
bold_no_wait "==================================================================================================================================="
bold_no_wait "Enter the login token for each cluster at https://console.cloud.google.com/anthos/clusters?project=${PLATFORM_PROJECT_ID}"
bold_no_wait "==================================================================================================================================="
echo

check_local_error
total_runtime
exit ${local_error}
