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

health_check_name=abm-asm-lb-health-check
title_no_wait "Creating TCP health check '${health_check_name}'"
print_and_execute "gcloud compute health-checks create tcp ${health_check_name} --project=${PLATFORM_PROJECT_ID} --use-serving-port"

export KUBECONFIG=$(ls -1 ${BMCTL_WORKSPACE_DIR}/*/*-kubeconfig | tr '\n' ':')
for cluster_name in $(get_cluster_names); do
    load_cluster_config ${cluster_name}

    address_name=${cluster_name}-asm-address

    network_args="--network ${NETWORK}"
    if [ ${USE_SHARED_VPC,,} == "true" ]; then
        network_args="--network projects/${NETWORK_PROJECT_ID}/global/networks/${NETWORK} --subnet projects/${NETWORK_PROJECT_ID}/regions/${REGION}/subnetworks/${SUBNET}"
    fi

    bold_no_wait "Creating Anthos Service Mesh (ASM) load balancer address '${address_name}' for '${cluster_name}'"
    print_and_execute "gcloud compute addresses create ${address_name} --project=${PLATFORM_PROJECT_ID} --global"

    title_no_wait "Creating the ASM load balancer for ${cluster_name}"

    bold_no_wait "Getting node ports"
    http_node_port=$(kubectl --context=${cluster_name} --namespace ${ASM_GATEWAY_NAMESPACE} get service/istio-ingressgateway --output jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
    echo "HTTP:  ${http_node_port}"
    https_node_port=$(kubectl --context=${cluster_name} --namespace ${ASM_GATEWAY_NAMESPACE} get service/istio-ingressgateway --output jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
    echo "HTTPS: ${https_node_port}"

    address=$(gcloud compute addresses describe ${address_name} --project=${PLATFORM_PROJECT_ID} --global --format "value(address)")
    bold_no_wait "Patching the istio-ingressgateway service for external IP '${address}'"
    patch_file=/tmp/asm-external-ip-patch.yaml
    cat <<EOF > ${patch_file}
spec:
  externalIPs:
    - ${address}
  loadBalancerIP: ${address}
EOF
    kubectl --context=${cluster_name} --namespace ${ASM_GATEWAY_NAMESPACE} patch service/istio-ingressgateway --patch "$(cat ${patch_file})" && rm -f ${patch_file}

    neg_80_name=${cluster_name}-asm-80-neg
    bold_no_wait "Creating network endpoint group '${neg_80_name}'"
    print_and_execute "gcloud compute network-endpoint-groups create ${neg_80_name} --project=${PLATFORM_PROJECT_ID} --network-endpoint-type=GCE_VM_IP_PORT --zone=${ZONE} ${network_args}"

    neg_443_name=${cluster_name}-asm-443-neg
    bold_no_wait "Creating network endpoint group '${neg_443_name}'"
    print_and_execute "gcloud compute network-endpoint-groups create ${neg_443_name} --project=${PLATFORM_PROJECT_ID} --network-endpoint-type=GCE_VM_IP_PORT --zone=${ZONE} ${network_args}"

    firewall_rule_name=allow-${cluster_name}-asm-proxy-and-health-check 
    firewall_rule_tag=${cluster_name}-asm-lb
    title_no_wait "Creating the firewall rule '${firewall_rule_name}' with tags '${firewall_rule_tag}'"
    print_and_execute "gcloud compute firewall-rules create ${firewall_rule_name} --project=${NETWORK_PROJECT_ID} --allow tcp:${http_node_port},tcp:${https_node_port} --source-ranges 130.211.0.0/22,35.191.0.0/16 --target-tags ${firewall_rule_tag}"

    for worker in $(seq 1 $(get_number_of_worker_nodes)); do
        hostname="${cluster_name}-worker-${worker}"

        bold_no_wait "Adding ${hostname} in ${ZONE} to ${neg_80_name}"
        print_and_execute "gcloud compute network-endpoint-groups update ${neg_80_name} --project=${PLATFORM_PROJECT_ID} --zone=${ZONE} --add-endpoint='instance=${hostname},port=${http_node_port}'"

        bold_no_wait "Adding ${hostname} in ${ZONE} to ${neg_443_name}"
        print_and_execute "gcloud compute network-endpoint-groups update ${neg_443_name} --project=${PLATFORM_PROJECT_ID} --zone=${ZONE} --add-endpoint='instance=${hostname},port=${https_node_port}'"

        bold_no_wait "Adding tag ${firewall_rule_tag} to ${hostname}"
        print_and_execute "gcloud compute instances add-tags ${hostname} --project=${PLATFORM_PROJECT_ID} --zone=${ZONE} --tags=${firewall_rule_tag}"
    done

    backend_80_name=${cluster_name}-asm-80-lb
    bold_no_wait "Creating backend '${backend_80_name}'"
    print_and_execute "gcloud compute backend-services create ${backend_80_name} --project=${PLATFORM_PROJECT_ID} --global --health-checks=${health_check_name} --protocol=HTTP"

    bold_no_wait "Adding '${neg_80_name}' to '${backend_80_name}'"
    print_and_execute "gcloud compute backend-services add-backend ${backend_80_name} --project=${PLATFORM_PROJECT_ID} --balancing-mode=RATE --global --max-rate=1000 --network-endpoint-group=${neg_80_name} --network-endpoint-group-zone=${ZONE}"
    
    url_map_name=${cluster_name}-asm-url-map
    bold_no_wait "Creating URL map '${url_map_name}'"
    print_and_execute "gcloud compute url-maps create ${url_map_name} --project=${PLATFORM_PROJECT_ID} --default-service=${backend_80_name}"

    http_proxy_name=${cluster_name}-asm-http-proxy
    bold_no_wait "Creating HTTP proxy '${http_proxy_name}'"
    print_and_execute "gcloud compute target-http-proxies create ${http_proxy_name} --project=${PLATFORM_PROJECT_ID} --url-map=${url_map_name}"

    forwarding_rule_name=${cluster_name}-asm-80-forwarding-rule
    bold_no_wait "Creating forwarding rule '${forwarding_rule_name}'"
    print_and_execute "gcloud compute forwarding-rules create ${forwarding_rule_name} --project=${PLATFORM_PROJECT_ID} --address=${address_name} --global --ports=80 --target-http-proxy=${http_proxy_name}"

    backend_443_name=${cluster_name}-asm-443-lb
    bold_no_wait "Creating backend '${backend_443_name}'"
    print_and_execute "gcloud compute backend-services create ${backend_443_name} --project=${PLATFORM_PROJECT_ID} --global --health-checks=${health_check_name} --protocol=TCP"

    bold_no_wait "Adding '${neg_443_name}' to '${backend_443_name}'"
    print_and_execute "gcloud compute backend-services add-backend ${backend_443_name} --project=${PLATFORM_PROJECT_ID} --balancing-mode=CONNECTION --global --max-connections=1000 --network-endpoint-group=${neg_443_name} --network-endpoint-group-zone=${ZONE}"

    tcp_proxy_name=${cluster_name}-asm-tcp-proxy
    bold_no_wait "Creating TCP proxy '${tcp_proxy_name}'"
    print_and_execute "gcloud compute target-tcp-proxies create ${tcp_proxy_name} --project=${PLATFORM_PROJECT_ID} --backend-service=${backend_443_name}"

    forwarding_rule_name=${cluster_name}-asm-443-forwarding-rule
    bold_no_wait "Creating forwarding rule '${forwarding_rule_name}'"
    print_and_execute "gcloud compute forwarding-rules create ${forwarding_rule_name} --project=${PLATFORM_PROJECT_ID} --address=${address_name} --global --ports=443 --target-tcp-proxy=${tcp_proxy_name}"
done

check_local_error
total_runtime
exit ${local_error}
