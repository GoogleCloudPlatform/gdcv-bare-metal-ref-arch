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
IP_FILE=${ABM_WORK_DIR}/scripts/ip.sh

source ${HOST_FILE}
source ${IP_FILE}

for cluster in $(seq 1 $NUM_CLUSTERS); do
    zone=${ZONE[${cluster}]}

    readarray -t HOST_IPS <<< `env | egrep "^METAL_${cluster}_" | grep -v '_IP=' | sort | awk -F= '{print $2}'`

    for cp in $(seq 1 $NUM_CP_NODES); do
        hostname="metal-${cluster}-prod-cp-${cp}"
        title_no_wait "${hostname}"

        env_var_hostname=`echo ${hostname//-/_} | tr [:lower:] [:upper:]`
        vxlan_ip_var="${env_var_hostname}_IP"
        vxlan_ip=${!vxlan_ip_var}

        print_and_execute "ping -c 3 ${vxlan_ip}"
    done

    for worker in $(seq 1 $NUM_WORKER_NODES); do
        hostname="metal-${cluster}-prod-worker-${worker}"
        title_no_wait "${hostname}"

        env_var_hostname=`echo ${hostname//-/_} | tr [:lower:] [:upper:]`
        vxlan_ip_var="${env_var_hostname}_IP"
        vxlan_ip=${!vxlan_ip_var}

        print_and_execute "ping -c 3 ${vxlan_ip}"
    done
done

check_local_error
total_runtime
exit ${local_error}
