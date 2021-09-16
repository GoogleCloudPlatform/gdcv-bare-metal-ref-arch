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

firewall_rule_name=allow-abm-cp-proxy-and-health-check 
firewall_rule_tag=abm-cp-lb
title_no_wait "Creating the firewall rule '${firewall_rule_name}' with tags '${firewall_rule_tag}'"
print_and_execute "gcloud compute firewall-rules create ${firewall_rule_name} --allow tcp:6444 --source-ranges 130.211.0.0/22,35.191.0.0/16 --target-tags ${firewall_rule_tag}"

health_check_name=abm-cp-lb-health-check
title_no_wait "Creating HTTPS health check '${health_check_name}'"
print_and_execute "gcloud compute health-checks create https ${health_check_name} --port=6444 --request-path=/readyz"

for cluster_name in $(get_cluster_names); do
    title_no_wait "Creating the control plane load balancer for ${cluster_name}"
    load_cluster_config ${cluster_name}

    address_name=${cluster_name}-cp-address
    bold_no_wait "Creating address '${address_name}'"
    print_and_execute "gcloud compute addresses create ${address_name} --global"

    neg_name=${cluster_name}-cp-neg
    bold_no_wait "Creating network endpoint group '${neg_name}'"
    print_and_execute "gcloud compute network-endpoint-groups create ${neg_name} --network-endpoint-type=GCE_VM_IP_PORT --zone=${ZONE} --network=default"

    for cp in $(seq 1 $(get_number_of_control_plane_nodes)); do
        hostname="${cluster_name}-cp-${cp}"
        
        bold_no_wait "Adding ${hostname} in ${ZONE} to ${neg_name}"
        print_and_execute "gcloud compute network-endpoint-groups update ${neg_name} --zone=${ZONE} --add-endpoint='instance=${hostname},port=6444'"

        bold_no_wait "Adding tag ${firewall_rule_tag} to ${hostname}"
        print_and_execute "gcloud compute instances add-tags ${hostname} --zone=${ZONE} --tags=${firewall_rule_tag}"
    done

    backend_name=${cluster_name}-cp-lb
    bold_no_wait "Creating backend '${backend_name}'"
    print_and_execute "gcloud compute backend-services create ${backend_name} --global --health-checks=${health_check_name} --protocol=TCP"

    bold_no_wait "Adding '${neg_name}' to '${backend_name}'"
    print_and_execute "gcloud compute backend-services add-backend ${backend_name} --balancing-mode=CONNECTION --global --max-connections=1000 --network-endpoint-group=${neg_name} --network-endpoint-group-zone=${ZONE}"

    tcp_proxy_name=${cluster_name}-cp-tcp-proxy
    bold_no_wait "Creating TCP proxy '${tcp_proxy_name}'"
    print_and_execute "gcloud compute target-tcp-proxies create ${tcp_proxy_name} --backend-service=${backend_name}"

    forwarding_rule_name=${cluster_name}-cp-forwarding-rule
    bold_no_wait "Creating forwarding rule '${forwarding_rule_name}'"
    print_and_execute "gcloud compute forwarding-rules create ${forwarding_rule_name} --address=${address_name} --global --ports=443 --target-tcp-proxy=${tcp_proxy_name}"
done

check_local_error
total_runtime
exit ${local_error}
