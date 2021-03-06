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

LOG_FILE_PREFIX=gcp-
source ${ABM_WORK_DIR}/scripts/helpers/include.sh

for cluster_name in $(get_cluster_names); do
    load_cluster_config ${cluster_name}
    
    network_args="--network ${NETWORK_NAME}"
    if [ ${USE_SHARED_VPC,,} == "true" ]; then
        network_args="--subnet projects/${NETWORK_PROJECT_ID}/regions/${REGION}/subnetworks/default"
    fi

    for worker in $(seq 1 $(get_number_of_worker_nodes)); do
        hostname="${cluster_name}-worker-${worker}"

        title_no_wait "Delete ${hostname} in ${ZONE}"
        print_and_execute "gcloud compute instances delete ${hostname} \
--delete-disks=all \
--project=${PLATFORM_PROJECT_ID} \
--quiet \
--zone=${ZONE}"
    done

    for cp in $(seq 1 $(get_number_of_control_plane_nodes)); do
        hostname="${cluster_name}-cp-${cp}"
    
        title_no_wait "Delete ${hostname} in ${ZONE}"
        print_and_execute "gcloud compute instances delete ${hostname} \
--delete-disks=all \
--project=${PLATFORM_PROJECT_ID} \
--quiet \
--zone=${ZONE}"
    done
done

print_and_execute "sudo rm -f ~/.ssh/known_hosts"
print_and_execute "sudo rm -f ~${DEPLOYMENT_USER}/.ssh/known_hosts"

check_local_error
total_runtime
exit ${local_error}
