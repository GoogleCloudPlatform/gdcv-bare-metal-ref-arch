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

title_no_wait "Upgrading clusters to ${BMCTL_VERSION_UPGRADE}"
print_and_execute "cd ${ABM_WORK_DIR}"
for cluster_name in $(get_cluster_names); do
    kubeconfig=${BMCTL_WORKSPACE_DIR}/${cluster_name}/${cluster_name}-kubeconfig

    if [ ${BMCTL_VERSION} == ${BMCTL_VERSION_UPGRADE} ]; then
        bold_no_wait "BMCTL_VERSION(${BMCTL_VERSION}) is the same as BMCTL_VERSION_UPGRADE(${BMCTL_VERSION_UPGRADE}), skipping backup"
    else

        backup_file="${BMCTL_WORKSPACE_DIR}/${cluster_name}/pre-upgrade_${BMCTL_VERSION}_to_${BMCTL_VERSION_UPGRADE}-bkp.tar.gz"
        if [ -f ${backup_file} ]; then
            bold_no_wait "Backup file '${backup_file}' already exists, skipping backup"
        else
            title_no_wait "Backing up ${cluster_name} to ${backup_file}"
            print_and_execute "${bmctl_binary_name} --workspace-dir ${BMCTL_WORKSPACE_DIR} backup cluster --backup-file ${backup_file} --cluster ${cluster_name} --kubeconfig ${kubeconfig} --yes"
        fi 
    fi

    title_no_wait "Upgrading ${cluster_name}"
    print_and_execute "${bmctl_binary_name} --workspace-dir ${BMCTL_WORKSPACE_DIR} upgrade cluster --cluster ${cluster_name} --kubeconfig ${kubeconfig}"
done

check_local_error
total_runtime

if [[ ${local_error} -eq 0 ]]; then
    add_or_replace_env_var_in_file "${ENVIRONMENT_FILE}" "${BMCTL_VERSION}" "${BMCTL_VERSION_UPGRADE}"
fi

exit ${local_error}
