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

process_host () {
    title_no_wait "${hostname}"

    env_var_hostname=`echo ${hostname//-/_} | tr [:lower:] [:upper:]`
    ips=("${HOST_IPS[@]/${!env_var_hostname}}")
    vxlan_ip_var="${env_var_hostname}_IP"

    vxlan_ip=${!vxlan_ip_var}
    vxlan_octets=(${vxlan_ip//./ })

    VXLAN_FILE=${TEMP_DIR}/${hostname}.vxlan
    cat > ${VXLAN_FILE} << EOF
set -x
ip link add vxlan${vxlan_octets[1]} type vxlan id ${vxlan_octets[1]} dev ens4 dstport 0
for ip in ${ips[@]}; do
    /usr/sbin/bridge fdb append to 00:00:00:00:00:00 dst \$ip dev vxlan${vxlan_octets[1]}
done
ip addr add ${vxlan_ip}/20 dev vxlan${vxlan_octets[1]}
ip link set up dev vxlan${vxlan_octets[1]}
EOF

    print_and_execute "gcloud compute scp \
--project=${PLATFORM_PROJECT_ID} \
--zone=${zone} \
${VXLAN_FILE} ${hostname}:/tmp/vxlan-setup"

    print_and_execute "gcloud compute scp \
--project=${PLATFORM_PROJECT_ID} \
--zone=${zone} \
${VXLAN_CRONTAB_FILE} ${hostname}:/tmp/vxlan.crontab"

    print_and_execute "gcloud compute ssh \
--command=\"sudo mv /tmp/vxlan-setup ${VXLAN_CRONJOB_FILE} \
&& sudo chmod +x ${VXLAN_CRONJOB_FILE} \
&& sudo chown ${DEPLOYMENT_USER}:${DEPLOYMENT_USER} ${VXLAN_CRONJOB_FILE} \
&& sudo crontab /tmp/vxlan.crontab\" \
--project=${PLATFORM_PROJECT_ID} \
--zone=${zone} \
${hostname}"
}

LOG_FILE_PREFIX=gcp-
source ${ABM_WORK_DIR}/scripts/helpers/include.sh

HOST_FILE=${ABM_WORK_DIR}/scripts/host.sh
IP_FILE=${ABM_WORK_DIR}/scripts/ip.sh

source ${HOST_FILE}
source ${IP_FILE}

TEMP_DIR=${ABM_WORK_DIR}/tmp/vxlan
mkdir -p ${TEMP_DIR}

ADMIN_CRONJOB_FILE=${TEMP_DIR}/admin.vxlan

VXLAN_CRONTAB_FILE=${TEMP_DIR}/vxlan.crontab
VXLAN_CRONJOB_FILE=/etc/cron.d/vxlan-setup
echo "* * * * * systemd-cat -t vxlan-setup ${VXLAN_CRONJOB_FILE}" > ${VXLAN_CRONTAB_FILE}

echo "sudo ip link add vxlan185 type vxlan id 185 dev ens4 dstport 0" > ${ADMIN_CRONJOB_FILE}
echo "sudo ip link add vxlan195 type vxlan id 195 dev ens4 dstport 0" >> ${ADMIN_CRONJOB_FILE}

for cluster in $(seq 1 $NUM_CLUSTERS); do
    zone=${ZONE[${cluster}]}

    readarray -t HOST_IPS <<< `env | egrep "^METAL_${cluster}_" | grep -v '_IP=' | sort | awk -F= '{print $2}'`

    for cp in $(seq 1 $NUM_CP_NODES); do
        hostname="metal-${cluster}-prod-cp-${cp}"
        process_host
    done

    for worker in $(seq 1 $NUM_WORKER_NODES); do
        hostname="metal-${cluster}-prod-worker-${worker}"
        process_host
    done

    for ip in ${HOST_IPS[@]}; do
        echo "/usr/sbin/bridge fdb append to 00:00:00:00:00:00 dst $ip dev vxlan${vxlan_octets[1]}" >> ${ADMIN_CRONJOB_FILE}
    done
done

echo "ip addr add 10.185.0.10/20 dev vxlan185" >> ${ADMIN_CRONJOB_FILE}
echo "ip addr add 10.195.0.10/20 dev vxlan195" >> ${ADMIN_CRONJOB_FILE}
echo "ip link set up dev vxlan185" >> ${ADMIN_CRONJOB_FILE}
echo "ip link set up dev vxlan195" >> ${ADMIN_CRONJOB_FILE}

sudo chmod +x ${ADMIN_CRONJOB_FILE}
sudo mv ${ADMIN_CRONJOB_FILE} ${VXLAN_CRONJOB_FILE}
sudo crontab ${VXLAN_CRONTAB_FILE}

check_local_error
total_runtime
exit ${local_error}