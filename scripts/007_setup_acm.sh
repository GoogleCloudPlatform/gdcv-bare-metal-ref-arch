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

ABM_ACM_GSA_NAME="anthos-config-mgmt"
ABM_ACM_GSA="${ABM_ACM_GSA_NAME}@${PLATFORM_PROJECT_ID}.iam.gserviceaccount.com"

gcloud iam service-accounts create ${ABM_ACM_GSA_NAME}

gcloud projects add-iam-policy-binding ${PLATFORM_PROJECT_ID} \
  --member serviceAccount:${ABM_ACM_GSA} \
  --role roles/source.reader

gcloud iam service-accounts add-iam-policy-binding \
   --role roles/iam.workloadIdentityUser \
   --member "serviceAccount:${PLATFORM_PROJECT_ID}.svc.id.goog[config-management-system/root-reconciler]" \
   ${ABM_ACM_GSA}


ACM_SOURCE_REPOSITORY="https://source.developers.google.com/p/${PLATFORM_PROJECT_ID}/r/acm"

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
    syncRepo: ${ACM_SOURCE_REPOSITORY}
    syncBranch: main
    secretType: gcpserviceaccount
    gcpServiceAccountEmail: ${ABM_ACM_GSA}
    policyDir: .
  policyController:
    enabled: true
EOF
    bold_no_wait "Apply the apply-spec.yaml"
    print_and_execute "gcloud beta container hub config-management apply --membership=${cluster_name} --config=${TEMP_DIR}/apply-spec.yaml --project=${PLATFORM_PROJECT_ID}"
done

title_no_wait "Waiting for ACM sync and install to complete"
while [[ $(gcloud beta container hub config-management status --project=${PLATFORM_PROJECT_ID} --filter="(acm_status.config_sync!=SYNCED AND acm_status.config_sync!=INSTALLED)" 2>/dev/null | wc -l) != "0" ]]; do
    sleep 5
done

test_namespace="acm-test"
for current_cluster_name in $(get_cluster_names); do
    load_cluster_config ${current_cluster_name}

    while ! kubectl --context ${current_cluster_name} create namespace ${test_namespace} &>/dev/null; do
        sleep 5
    done

    kubectl --context ${current_cluster_name} delete namespace ${test_namespace} &>/dev/null
done

check_local_error
total_runtime
exit ${local_error}
