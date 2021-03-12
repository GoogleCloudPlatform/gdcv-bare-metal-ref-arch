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
for cluster_name in $(get_cluster_names); do
    title_no_wait "Creating configuration for ${cluster_name}"
    load_cluster_config ${cluster_name}

    control_plane_node_pool_addresses=""
    for cp_address in $(get_control_plane_node_addresses); do
        control_plane_node_pool_addresses+=$(printf "      - address: %s\n" "${cp_address}")
    done
    export CONTROL_PLANE_NODE_POOL=${control_plane_node_pool_addresses}

    worker_node_pool_addresses=""
    for worker_address in $(get_worker_node_addresses); do
        worker_node_pool_addresses+=$(printf "  - address: %s\n" "${worker_address}")
    done
    export WORKER_NODE_POOL=${worker_node_pool_addresses}

    bold_no_wait "${cluster_name}"
    cluster_yaml=bmctl-workspace/${cluster_name}/${cluster_name}.yaml
    if [ ! -f "${cluster_yaml}" ]; then
        print_and_execute "bmctl create config --cluster ${cluster_name} --create-service-accounts --enable-apis --project-id ${PLATFORM_PROJECT_ID}"
        if [ $? -eq 0 ]; then
            bold_no_wait "Applying kustomizations"

            cp -p ${cluster_yaml} ${cluster_yaml}.orig
            sed -i '0,/^---$/d' ${cluster_yaml}

            KUSTOMIZATIONS_TYPE="hybrid"
            envsubst <  ${ABM_WORK_DIR}/kustomizations/${KUSTOMIZATIONS_TYPE}/kustomization.yaml > ${ABM_WORK_DIR}/bmctl-workspace/${cluster_name}/kustomization.yaml
            envsubst <  ${ABM_WORK_DIR}/kustomizations/${KUSTOMIZATIONS_TYPE}/patch.yaml> ${ABM_WORK_DIR}/bmctl-workspace/${cluster_name}/patch.yaml

            kubectl kustomize bmctl-workspace/${cluster_name} > ${cluster_yaml}.tmp
            mv ${cluster_yaml}.tmp ${cluster_yaml}
            
            cat ${ABM_WORK_DIR}/kustomizations/bmctl-config.yaml | envsubst > ${ABM_WORK_DIR}/bmctl-workspace/${cluster_name}/bmctl-config.yaml
            cat ${ABM_WORK_DIR}/bmctl-workspace/${cluster_name}/bmctl-config.yaml ${cluster_yaml} > ${cluster_yaml}.tmp
            mv ${cluster_yaml}.tmp ${cluster_yaml}

            bold_no_wait "Checking configuration"
            print_and_execute "bmctl check config --cluster ${cluster_name}"
            echo
        else
            error_no_wait "There was an error generating the configuration for cluster '${cluster_name}'"
        fi
    else
        error_no_wait "Configuration for cluster '${cluster_name}' already exists at ${cluster_yaml}."
        error_no_wait "Delete the existing configuration file to generate a new configuration file"
    fi

    unset CONTROL_PLANE_NODE_POOL
    unset WORKER_NODE_POOL
done

mkdir -p ${ABM_WORK_DIR}/keys
sudo cp ${DEPLOYMENT_USER_SSH_KEY} ${ABM_WORK_DIR}/keys/id_rsa
sudo chown ${USER}:${USER} ${ABM_WORK_DIR}/keys/id_rsa

check_local_error
total_runtime
exit ${local_error}
