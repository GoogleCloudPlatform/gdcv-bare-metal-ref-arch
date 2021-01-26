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

sudo ip link add vxlan185 type vxlan id 185 dev ens4 dstport 0
sudo ip link add vxlan195 type vxlan id 195 dev ens4 dstport 0

for cluster in $(seq 1 $NUM_CLUSTERS); do
    zone=${ZONE[${cluster}]}

    readarray -t HOST_IPS <<< `env | egrep "^METAL_${cluster}_" | grep -v '_IP=' | sort | awk -F= '{print $2}'`

    for cp in $(seq 1 $NUM_CP_NODES); do
        hostname="metal-${cluster}-prod-cp-${cp}"
        title_no_wait "${hostname}"

        env_var_hostname=`echo ${hostname//-/_} | tr [:lower:] [:upper:]`
        ips=("${HOST_IPS[@]/${!env_var_hostname}}")
        vxlan_ip_var="${env_var_hostname}_IP"

        vxlan_ip=${!vxlan_ip_var}
        vxlan_octets=(${vxlan_ip//./ })

        gcloud compute ssh ${hostname} --zone=${zone} << EOF
set -x
sudo ip link add vxlan${vxlan_octets[1]} type vxlan id ${vxlan_octets[1]} dev ens4 dstport 0
for ip in ${ips[@]}; do
    sudo bridge fdb append to 00:00:00:00:00:00 dst \$ip dev vxlan${vxlan_octets[1]}
done
sudo ip addr add ${vxlan_ip}/20 dev vxlan${vxlan_octets[1]}
sudo ip link set up dev vxlan${vxlan_octets[1]}
EOF
    done

    for worker in $(seq 1 $NUM_WORKER_NODES); do
        hostname="metal-${cluster}-prod-worker-${worker}"
        title_no_wait "${hostname}"

        env_var_hostname=`echo ${hostname//-/_} | tr [:lower:] [:upper:]`
        ips=("${HOST_IPS[@]/${!env_var_hostname}}")
        vxlan_ip_var="${env_var_hostname}_IP"

        vxlan_ip=${!vxlan_ip_var}
        vxlan_octets=(${vxlan_ip//./ })

        gcloud compute ssh ${hostname} --zone=${zone} << EOF
set -x
sudo ip link add vxlan${vxlan_octets[1]} type vxlan id ${vxlan_octets[1]} dev ens4 dstport 0
for ip in ${ips[@]}; do
    sudo bridge fdb append to 00:00:00:00:00:00 dst \$ip dev vxlan${vxlan_octets[1]}
done
sudo ip addr add ${vxlan_ip}/20 dev vxlan${vxlan_octets[1]}
sudo ip link set up dev vxlan${vxlan_octets[1]}
EOF
    done

    for ip in ${HOST_IPS[@]}; do
        sudo bridge fdb append to 00:00:00:00:00:00 dst $ip dev vxlan${vxlan_octets[1]}
    done
done

sudo ip addr add 10.185.0.10/20 dev vxlan185
sudo ip addr add 10.195.0.10/20 dev vxlan195
sudo ip link set up dev vxlan185
sudo ip link set up dev vxlan195

check_local_error
total_runtime
exit ${local_error}