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

for cluster in $(seq 1 $NUM_CLUSTERS); do
    zone=${ZONE[${cluster}]}
    for worker in $(seq 1 $NUM_WORKER_NODES); do
        title_no_wait "Delete metal-${cluster}-prod-worker-${worker} in ${ZONE[${cluster}]}"
        print_and_execute "gcloud compute instances delete metal-${cluster}-prod-worker-${worker} \
--delete-disks=all \
--project=${PLATFORM_PROJECT_ID} \
--quiet \
--zone=${zone}"
    done
    
    for cp in $(seq 1 $NUM_CP_NODES); do
        title_no_wait "Delete metal-${cluster}-prod-cp-${cp} in ${ZONE[${cluster}]}"
        print_and_execute "gcloud compute instances delete metal-${cluster}-prod-cp-${cp} \
--delete-disks=all \
--project=${PLATFORM_PROJECT_ID} \
--quiet \
--zone=${zone}"
    done
done

print_and_execute "sudo rm -f ~/.ssh/known_hosts"
print_and_execute "sudo rm -f ~${DEPLOYMENT_USER}/.ssh/known_hosts"

check_local_error
total_runtime
exit ${local_error}
