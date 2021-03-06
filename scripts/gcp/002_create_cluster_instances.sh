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

LOG_FILE_PREFIX=gcp-
source ${ABM_WORK_DIR}/scripts/helpers/include.sh

for cluster_name in $(get_cluster_names); do
    title_no_wait "Creating instances for ${cluster_name}"
    load_cluster_config ${cluster_name}

    network_args="--network ${NETWORK_NAME}"
    if [ ${USE_SHARED_VPC,,} == "true" ]; then
        network_args="--subnet projects/${NETWORK_PROJECT_ID}/regions/${REGION}/subnetworks/default"
    fi

    for cp in $(seq 1 $(get_number_of_control_plane_nodes)); do
        hostname="${cluster_name}-cp-${cp}"
        
        title_no_wait "${hostname} in ${ZONE}"
        print_and_execute "gcloud compute instances create ${hostname} \
--boot-disk-size 512G \
--boot-disk-type pd-ssd \
--can-ip-forward \
--image-family=ubuntu-2004-lts \
--image-project=ubuntu-os-cloud \
--machine-type=${CP_MACHINE_TYPE} \
--metadata-from-file startup-script=${ABM_WORK_DIR}/scripts/gcp/instance_startup_script.sh \
--no-scopes \
--no-service-account \
--project=${PLATFORM_PROJECT_ID} \
--quiet \
--zone=${ZONE} \
${network_args}"
    done

    for worker in $(seq 1 $(get_number_of_worker_nodes)); do
        hostname="${cluster_name}-worker-${worker}"
        
        title_no_wait "${hostname} in ${ZONE}"
        print_and_execute "gcloud compute instances create ${hostname} \
--boot-disk-size 512G \
--boot-disk-type pd-ssd \
--can-ip-forward \
--image-family=ubuntu-2004-lts \
--image-project=ubuntu-os-cloud \
--machine-type=${WORKER_MACHINE_TYPE} \
--metadata-from-file startup-script=${ABM_WORK_DIR}/scripts/gcp/instance_startup_script.sh \
--no-scopes \
--no-service-account \
--project=${PLATFORM_PROJECT_ID} \
--quiet \
--zone=${ZONE} \
${network_args}"
    done
done

check_local_error
total_runtime
exit ${local_error}
