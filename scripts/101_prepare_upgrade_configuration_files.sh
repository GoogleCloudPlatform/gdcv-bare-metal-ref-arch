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

if [ -z ${BMCTL_VERSION_UPGRADE} ]; then
    error_no_wait "BMCTL_VERSION_UPGRADE environment variable must be set to the new version"
    exit -1
fi

bmctl_binary_name="bmctl_${BMCTL_VERSION_UPGRADE}"
title_no_wait "Downloading ${BMCTL_VERSION_UPGRADE} binary"

mkdir -p ${ABM_WORK_DIR}/bin
print_and_execute "gsutil cp gs://anthos-baremetal-release/bmctl/${BMCTL_VERSION_UPGRADE}/linux-amd64/bmctl ${ABM_WORK_DIR}/bin/${bmctl_binary_name}"
print_and_execute "chmod a+x ${ABM_WORK_DIR}/bin/${bmctl_binary_name}"
print_and_execute "sudo cp -p ${ABM_WORK_DIR}/bin/${bmctl_binary_name} /usr/local/bin/"

if [ ! -f /usr/local/bin/${bmctl_binary_name} ]; then
    error_no_wait "Failed to download or install '${bmctl_binary_name}', exiting!"
    exit -1
fi

title_no_wait "Updating cluster configurations"
cd ${ABM_WORK_DIR}
for cluster_name in $(get_cluster_names); do
    title_no_wait "Updating configuration for ${cluster_name}"
    load_cluster_config ${cluster_name}

    cluster_yaml=${BMCTL_WORKSPACE_DIR}/${cluster_name}/${cluster_name}.yaml
    if [ -f "${cluster_yaml}" ]; then
	bold_no_wait "Updating anthosBareMetalVersion to ${BMCTL_VERSION_UPGRADE} in ${cluster_yaml}"
        sed -i "/  anthosBareMetalVersion:/c\  anthosBareMetalVersion: ${BMCTL_VERSION_UPGRADE}" ${cluster_yaml}
	#TODO: add error checking

        bold_no_wait "Checking configuration"
        print_and_execute "${bmctl_binary_name} --workspace-dir ${BMCTL_WORKSPACE_DIR} check config --cluster ${cluster_name}"
        echo
    else
        error_no_wait "Configuration for cluster '${cluster_name}' does not exists at ${cluster_yaml}."
    fi

done

mkdir -p ${ABM_WORK_DIR}/keys
sudo cp -p ${DEPLOYMENT_USER_SSH_KEY} ${ABM_WORK_DIR}/keys/id_rsa
sudo chown ${USER}:${USER} ${ABM_WORK_DIR}/keys/id_rsa

check_local_error
total_runtime
exit ${local_error}
