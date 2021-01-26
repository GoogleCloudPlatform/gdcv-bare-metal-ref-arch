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
source ${ABM_WORK_DIR}/scripts/ip.sh

title_no_wait "Download bmctl-${BMCTL_VERSION} binary"

mkdir -p ${ABM_WORK_DIR}/bin
print_and_execute "gsutil cp gs://anthos-baremetal-release/bmctl/${BMCTL_VERSION}/linux-amd64/bmctl ${ABM_WORK_DIR}/bin/bmctl"
print_and_execute "chmod a+x ${ABM_WORK_DIR}/bin/bmctl"
print_and_execute "sudo cp -p ${ABM_WORK_DIR}/bin/bmctl /usr/local/bin/"

if [ ! -f /usr/local/bin/bmctl ]; then
    error_no_wait "Failed to download or install 'bmctl', exiting!"
    exit -1
fi

title_no_wait "Create cluster configurations"
cd ${ABM_WORK_DIR}
for cluster_num in $(seq 1 $NUM_CLUSTERS); do
    cluster_name=${CLUSTER_NAME["$cluster_num"]}

    bold_no_wait "${cluster_name}"
    cluster_yaml=bmctl-workspace/${cluster_name}/${cluster_name}.yaml
    if [ ! -f "${cluster_yaml}" ]; then
        print_and_execute "bmctl create config --cluster ${cluster_name} --create-service-accounts --enable-apis --project-id ${PLATFORM_PROJECT_ID}"
        if [ $? -eq 0 ]; then
            bold_no_wait "Applying kustomizations"
            cp -p ${cluster_yaml} ${cluster_yaml}.orig
            sed -i '0,/^---$/d' ${cluster_yaml}

            cp -p ${ABM_WORK_DIR}/kustomizations/${cluster_name}/* ${ABM_WORK_DIR}/bmctl-workspace/${cluster_name}/
            kubectl kustomize bmctl-workspace/${cluster_name} | envsubst > ${cluster_yaml}.tmp
            sed '/- address: $/d' -i ${cluster_yaml}.tmp
            mv ${cluster_yaml}.tmp ${cluster_yaml}
            
            cat ${ABM_WORK_DIR}/kustomizations/bmctl-config.yaml | envsubst > ${ABM_WORK_DIR}/bmctl-workspace/${cluster_name}/bmctl-config.yaml
            cat ${ABM_WORK_DIR}/bmctl-workspace/${cluster_name}/bmctl-config.yaml ${cluster_yaml} > ${cluster_yaml}.tmp
            mv ${cluster_yaml}.tmp ${cluster_yaml}
            echo ""
        else
            error_no_wait "There was an error generating the configuration for cluster '${cluster_name}'"
        fi
    else
        error_no_wait "Configuration for cluster '${cluster_name}' already exists at ${cluster_yaml}."
        error_no_wait "Delete the existing configuration file to generate a new configuration file"
    fi
done

mkdir -p ${ABM_WORK_DIR}/keys
sudo cp ${DEPLOYMENT_USER_SSH_KEY} ${ABM_WORK_DIR}/keys/id_rsa
sudo chown ${USER}:${USER} ${ABM_WORK_DIR}/keys/id_rsa

check_local_error
total_runtime
exit ${local_error}
