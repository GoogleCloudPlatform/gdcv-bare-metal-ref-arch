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

bc_installed=`which bc`
if [ -z ${bc_installed} ]; then
    title_no_wait "Install bc"
    nopv_and_execute "sudo apt-get update && sudo apt-get -y install bc"
fi

region_1_quota=$(gcloud compute regions describe ${REGION["1"]} --project ${PLATFORM_PROJECT_ID} --format "value(quotas[0].limit)")
region_2_quota=$(gcloud compute regions describe ${REGION["3"]} --project ${PLATFORM_PROJECT_ID} --format "value(quotas[0].limit)")

quota_error=0
if [ $(echo "${region_1_quota}>=96" | bc) -eq 0 ]; then
    error_no_wait "CPU quota for ${REGION["1"]} is ${region_1_quota} which is less than 96"
    quota_error=1
fi

if [ $(echo "${region_2_quota}>=96" | bc) -eq 0 ]; then
    error_no_wait "CPU quota for ${REGION["3"]} is ${region_2_quota} which is less than 96"
    quota_error=1
fi

if [ ${quota_error} -ne 0 ]; then
    error_no_wait "Quota limits do not meet the minimum requirements"
    bold_and_wait "Check CPU quotas at https://console.cloud.google.com/admin/quotas/details;servicem=compute.googleapis.com;metricm=compute.googleapis.com%2Fcpus;limitIdm=1%2F%7Bproject%7D?cloudshell=false&project=${PLATFORM_PROJECT_ID}"
fi

for cluster in $(seq 1 $NUM_CLUSTERS); do
    region=${REGION[${cluster}]}
    zone=${ZONE[${cluster}]}
    
    network_args="--network ${NETWORK_NAME}"
    if [ ${USE_SHARED_VPC,,} == "true" ]; then
        network_args="--subnet projects/${NETWORK_PROJECT_ID}/regions/${region}/subnetworks/default"
    fi

    for cp in $(seq 1 $NUM_CP_NODES); do
        hostname="metal-${cluster}-prod-cp-${cp}"
        
        title_no_wait "${hostname} in ${zone}"
        print_and_execute "gcloud compute instances create ${hostname} \
--boot-disk-size 512G \
--boot-disk-type pd-ssd \
--can-ip-forward \
--image-family=ubuntu-2004-lts \
--image-project=ubuntu-os-cloud \
--machine-type n1-standard-8 \
--metadata-from-file startup-script=${ABM_WORK_DIR}/scripts/gcp/instance_startup_script.sh \
--no-scopes \
--no-service-account \
--project=${PLATFORM_PROJECT_ID} \
--quiet \
--zone=${zone} \
${network_args}"
    done
    
    for worker in $(seq 1 $NUM_WORKER_NODES); do
        hostname="metal-${cluster}-prod-worker-${worker}"
        
        title_no_wait "${hostname} in ${zone}"
        print_and_execute "gcloud compute instances create ${hostname} \
--boot-disk-size 512G \
--boot-disk-type pd-ssd \
--can-ip-forward \
--image-family=ubuntu-2004-lts \
--image-project=ubuntu-os-cloud \
--machine-type n1-standard-8 \
--metadata-from-file startup-script=${ABM_WORK_DIR}/scripts/gcp/instance_startup_script.sh \
--no-scopes \
--no-service-account \
--project=${PLATFORM_PROJECT_ID} \
--quiet \
--zone=${zone} \
${network_args}"
    done
done

check_local_error
total_runtime
exit ${local_error}
