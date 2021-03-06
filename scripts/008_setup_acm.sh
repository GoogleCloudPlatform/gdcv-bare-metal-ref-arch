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

SCM_SSH_KEY=${ABM_WORK_DIR}/keys/scm_ssh_key
ACM_SOURCE_REPOSITORY=source.developers.google.com:2022/p/${PLATFORM_PROJECT_ID}/r/acm

ACM_REPO_DIRECTORY=${ABM_WORK_DIR}/acm

if [ ! -d ${ACM_REPO_DIRECTORY} ]; then
    title_no_wait "Create the Anthos Config Management(ACM) Cloud Source Repositories(CSR) repository"
    
    bold_no_wait "Enable sourcerepo.googleapis.com API"
    print_and_execute "gcloud services enable sourcerepo.googleapis.com --project ${PLATFORM_PROJECT_ID}"
    
    bold_no_wait "Create the repository"
    print_and_execute "gcloud source repos create acm --project ${PLATFORM_PROJECT_ID}"
    
    bold_no_wait "Initialize the repository"
    print_and_execute "gcloud source repos clone --project ${PLATFORM_PROJECT_ID} acm ${ACM_REPO_DIRECTORY}"
    print_and_execute "cp -a ${ABM_WORK_DIR}/starter_repos/acm/. ${ACM_REPO_DIRECTORY}/"
    cd ${ACM_REPO_DIRECTORY}
    git checkout -b main
    git config user.email "acm@anthos"
    git config user.name "ACM"
    git add .
    git commit -m "Initialize repository"
    git push --set-upstream origin main
fi

echo
bold_no_wait "=============================================================================================================="
bold_no_wait "ACM Repository created at: https://source.cloud.google.com/${PLATFORM_PROJECT_ID}/acm/+/main "
bold_no_wait "=============================================================================================================="
echo

GCP_ACCOUNT=$(gcloud config list account --format "value(core.account)")

if [ ! -f ${SCM_SSH_KEY} ]; then
    title_no_wait "Generate SSH key for ACM git access"
    print_and_execute "ssh-keygen -C acm -f ${SCM_SSH_KEY} -P '' -t rsa"
fi

echo
echo "SSH public key:"; cat ${SCM_SSH_KEY}.pub
echo
bold_no_wait "=============================================================================="
bold_no_wait "Add the SSH key at https://source.cloud.google.com/user/ssh_keys?register=true"
bold_no_wait "=============================================================================="
bold_and_wait "When the key has been added"

title_no_wait "Enabling the ACM feature"
print_and_execute "gcloud services enable --project ${PLATFORM_PROJECT_ID} anthosconfigmanagement.googleapis.com"
print_and_execute "gcloud alpha container hub config-management enable --project ${PLATFORM_PROJECT_ID}"

title_no_wait "Download config-management-operator.yaml"
gsutil cp gs://config-management-release/released/latest/config-management-operator.yaml ${TEMP_DIR}/

print_and_execute "cd ${ABM_WORK_DIR}"
export KUBECONFIG=$(ls -1 ${ABM_WORK_DIR}/bmctl-workspace/*/*-kubeconfig | tr '\n' ':')
for cluster_name in $(get_cluster_names); do    
    title_no_wait "Deploy ACM on ${cluster_name}"
    
    bold_no_wait "Generate ConfigManagement object"
    cat <<EOF > ${TEMP_DIR}/acm.yaml
apiVersion: configmanagement.gke.io/v1
kind: ConfigManagement
metadata:
  name: config-management
spec:
  clusterName: ${cluster_name}
  policyController:
    enabled: true
    templateLibraryInstalled: true
  git:
    syncRepo: ssh://${GCP_ACCOUNT}@${ACM_SOURCE_REPOSITORY}
    syncBranch: main
    secretType: ssh
EOF
    
    bold_no_wait "Apply config-management-operator.yaml"
    print_and_execute "kubectl --context=${cluster_name} apply -f ${TEMP_DIR}/config-management-operator.yaml"
    
    bold_no_wait "Create crm-credentials secret"
    print_and_execute "kubectl --context=${cluster_name} create secret generic git-creds --namespace=config-management-system --from-file=ssh=${SCM_SSH_KEY}"
    
    bold_no_wait "Apply ConfigManagement"
    print_and_execute "kubectl --context=${cluster_name} apply -f ${TEMP_DIR}/acm.yaml"
done

check_local_error
total_runtime
exit ${local_error}
