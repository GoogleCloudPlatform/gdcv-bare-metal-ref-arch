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

HOST_FILE=${ABM_WORK_DIR}/scripts/host.sh
truncate -s 0 ${HOST_FILE}

IP_FILE=${ABM_WORK_DIR}/scripts/ip.sh
truncate -s 0 ${IP_FILE}

NETWORK_OFFSET=57
CP_HOST_OFFSET=10
WORKER_HOST_OFFSET=17

for cluster in $(seq 1 $NUM_CLUSTERS); do
    zone=${ZONE[${cluster}]}
    
    for cp in $(seq 1 $NUM_CP_NODES); do
        hostname="metal-${cluster}-prod-cp-${cp}"
        
        title_no_wait "${hostname} in ${zone}"
        ip_address=$(gcloud compute instances describe ${hostname} --format="value(networkInterfaces[0].networkIP)" --project=${PLATFORM_PROJECT_ID} --zone=${zone})
        env_var_hostname=${hostname//-/_}
        
        echo "export ${env_var_hostname^^}=${ip_address}" >> ${HOST_FILE}
        
        ip_suffix=$((${cp} + ${CP_HOST_OFFSET}))
        echo "export ${env_var_hostname^^}_IP=${IP_PREFIX[${cluster}]}.${ip_suffix}" >> ${IP_FILE}
    done
    
    for worker in $(seq 1 $NUM_WORKER_NODES); do
        hostname="metal-${cluster}-prod-worker-${worker}"
        
        title_no_wait "${hostname} in ${zone}"
        ip_address=$(gcloud compute instances describe ${hostname} --format="value(networkInterfaces[0].networkIP)" --project=${PLATFORM_PROJECT_ID} --zone=${zone})
        env_var_hostname=${hostname//-/_}
        
        echo "export ${env_var_hostname^^}=${ip_address}" >> ${HOST_FILE}
        
        ip_suffix=$((${worker} + ${WORKER_HOST_OFFSET}))
        echo "export ${env_var_hostname^^}_IP=${IP_PREFIX[${cluster}]}.${ip_suffix}" >> ${IP_FILE}
    done
done

total_runtime
exit ${local_error}