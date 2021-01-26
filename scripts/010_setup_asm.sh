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

source ${ABM_WORK_DIR}/scripts/helpers/include.sh

ASM_DIR=/usr/local/share/istio-${ASM_VERSION}
TEMP_DIR=${ABM_WORK_DIR}/tmp
mkdir -p ${TEMP_DIR}

title_no_wait "Create istio-system.yaml"
kubectl create namespace istio-system --dry-run -o yaml > ${TEMP_DIR}/istio-system.yaml

title_no_wait "Create istiod-service.yaml"
cat <<EOF > ${TEMP_DIR}/istiod-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: istiod
  namespace: istio-system
  labels:
    istio.io/rev: ${ASM_REVISION}
    app: istiod
    istio: pilot
    release: istio
spec:
  ports:
    - port: 15010
      name: grpc-xds # plaintext
      protocol: TCP
    - port: 15012
      name: https-dns # mTLS with k8s-signed cert
      protocol: TCP
    - port: 443
      name: https-webhook # validation and injection
      targetPort: 15017
      protocol: TCP
    - port: 15014
      name: http-monitoring # prometheus stats
      protocol: TCP
  selector:
    app: istiod
    istio.io/rev: ${ASM_REVISION}
EOF

cd ${TEMP_DIR}

export KUBECONFIG=$(ls -1 ${ABM_WORK_DIR}/bmctl-workspace/*/*-kubeconfig | tr '\n' ':')
for cluster_num in $(seq 1 $NUM_CLUSTERS); do
    cluster_name=${CLUSTER_NAME["$cluster_num"]}
    
    title_no_wait "Create istio-system namespace on ${cluster_name}"
    print_and_execute "kubectl apply -f ${TEMP_DIR}/istio-system.yaml"
    
    title_no_wait "Install ASM on ${cluster_name}"
    
    print_and_execute "istioctl install --context=${cluster_name} --set profile=asm-multicloud --set revision=${ASM_REVISION}"
    echo
    
    # TODO: Is this needed or is it done by the installer?
    #kubectl apply -f istiod-service.yaml
done

check_local_error
total_runtime
exit ${local_error}
