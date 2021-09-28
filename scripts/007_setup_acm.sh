#!/usr/bin/env bash

# Copyright 2021 Google LLC
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
bold_no_wait "ACM Repository: https://source.cloud.google.com/${PLATFORM_PROJECT_ID}/acm/+/main:"
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
print_and_execute "gcloud services enable --project ${PLATFORM_PROJECT_ID} anthos.googleapis.com anthosconfigmanagement.googleapis.com"
print_and_execute "gcloud beta container hub config-management enable --project=${PLATFORM_PROJECT_ID}"

print_and_execute "cd ${ABM_WORK_DIR}"
export KUBECONFIG=$(ls -1 ${BMCTL_WORKSPACE_DIR}/*/*-kubeconfig | tr '\n' ':')
for cluster_name in $(get_cluster_names); do    
    title_no_wait "Deploy ACM on ${cluster_name}"
    
    bold_no_wait "Generate the apply-spec.yaml"
    cat <<EOF > ${TEMP_DIR}/apply-spec.yaml
applySpecVersion: 1
spec:
  configSync:
    enabled: true
    sourceFormat: hierarchy
    syncRepo: ssh://${GCP_ACCOUNT}@${ACM_SOURCE_REPOSITORY}
    syncBranch: main
    secretType: ssh
    policyDir: .
  policyController:
    enabled: true
EOF
    bold_no_wait "Create the config-management-system namespace"
    print_and_execute "kubectl --context=${cluster_name} create namespace config-management-system"

    bold_no_wait "Apply the apply-spec.yaml"
    print_and_execute "gcloud beta container hub config-management apply --membership=${cluster_name} --config=${TEMP_DIR}/apply-spec.yaml --project=${PLATFORM_PROJECT_ID}"

    bold_no_wait "Create git-creds secret"
    print_and_execute "kubectl --context=${cluster_name} create secret generic git-creds --namespace=config-management-system --from-file=ssh=${SCM_SSH_KEY}"
done

bold_no_wait "Wait for configuration updates to be applied"
sleep 60

export KUBECONFIG=$(ls -1 ${BMCTL_WORKSPACE_DIR}/*/*-kubeconfig | tr '\n' ':')
for cluster_name in $(get_cluster_names); do
    title_no_wait "Wating for ACM to deploy in ${cluster_name}"
    print_and_execute "kubectl --context=${cluster_name} --namespace=config-management-system wait --for=condition=available --timeout=600s deployments --all"
    print_and_execute "kubectl --context=${cluster_name} --namespace=gatekeeper-system wait --for=condition=available --timeout=600s deployments --all"
done

check_local_error
total_runtime
exit ${local_error}
