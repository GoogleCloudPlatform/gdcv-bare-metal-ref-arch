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

LOG_FILE_PREFIX=gcp-lb-
source ${ABM_WORK_DIR}/scripts/helpers/include.sh
source ${ABM_WORK_DIR}/scripts/helpers/files.sh

for cluster_name in $(get_cluster_names); do
    title_no_wait "Generating conf files for ${cluster_name}"
    load_cluster_config ${cluster_name}

    conf_file="${ABM_WORK_DIR}/conf/${cluster_name}"

    bold_no_wait "Processing control plane instance(s)"
    for cp in $(seq 1 $(get_number_of_control_plane_nodes)); do
        hostname="${cluster_name}-cp-${cp}"
        ip_address=$(gcloud compute instances describe ${hostname} --format="value(networkInterfaces[0].networkIP)" --project=${PLATFORM_PROJECT_ID} --zone=${ZONE})
        key="CP_${cp}_IP"
        
        add_or_replace_env_var_in_file "${conf_file}" "${key}" "${ip_address}"
    done

    bold_no_wait "Processing worker instance(s)"
    for worker in $(seq 1 $(get_number_of_worker_nodes)); do
        hostname="${cluster_name}-worker-${worker}"
        ip_address=$(gcloud compute instances describe ${hostname} --format="value(networkInterfaces[0].networkIP)" --project=${PLATFORM_PROJECT_ID} --zone=${ZONE})
        key="WORKER_${worker}_IP"
        
        add_or_replace_env_var_in_file "${conf_file}" "${key}" "${ip_address}"
    done

    bold_no_wait "Processing control plane load balancer"
    cp_lb_vip=$(gcloud compute addresses describe ${cluster_name}-cp-address --global --format='value(address)')
    add_or_replace_env_var_in_file "${conf_file}" "CP_LB_VIP" "${cp_lb_vip}"

    bold_no_wait "Processing ingress load balancer"
    ingress_lb_vip=$(gcloud compute addresses describe ${cluster_name}-ingress-address --global --format='value(address)')
    add_or_replace_env_var_in_file "${conf_file}" "INGRESS_LB_VIP" "${ingress_lb_vip}"

    bold_no_wait "Removing LB_ADDRESS_POOL"
    remove_env_var_in_file "${conf_file}" "LB_ADDRESS_POOL"
done

check_local_error
total_runtime
exit ${local_error}
