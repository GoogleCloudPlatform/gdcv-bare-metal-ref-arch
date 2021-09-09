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

source ${ABM_WORK_DIR}/scripts/helpers/include.sh

TEMP_DIR=${ABM_WORK_DIR}/tmp
ASM_TEMP_DIR=${TEMP_DIR}/asm-${ASM_VERSION}
mkdir -p ${ASM_TEMP_DIR}

if [ ! -f "${ASM_TEMP_DIR}/istio-${ASM_VERSION}-linux-amd64.tar.gz" ]; then
    title_no_wait "Download the Anthos Service Mesh v${ASM_VERSION} installation file"
    print_and_execute "curl --location --output ${ASM_TEMP_DIR}/istio-${ASM_VERSION}-linux-amd64.tar.gz --show-error --silent https://storage.googleapis.com/gke-release/asm/istio-${ASM_VERSION}-linux-amd64.tar.gz"
    print_and_execute "tar xzf ${ASM_TEMP_DIR}/istio-${ASM_VERSION}-linux-amd64.tar.gz --directory ${ASM_TEMP_DIR}"
fi
ASM_INSTALL_DIR=${ASM_TEMP_DIR}/istio-${ASM_VERSION}

KPT_BINARY=${ASM_TEMP_DIR}/kpt
KPT_VERSION=0.39.2
title_no_wait "Download kpt v${KPT_VERSION}"
print_and_execute "curl --location --output ${KPT_BINARY} --show-error --silent https://github.com/GoogleContainerTools/kpt/releases/download/v${KPT_VERSION}/kpt_linux_amd64"
print_and_execute "chmod +x ${KPT_BINARY}"

ASM_KPT_DIR=${ASM_TEMP_DIR}/asm-${ASM_RELEASE}
rm -rf ${ASM_KPT_DIR}
title_no_wait "Download the ASM ${ASM_RELEASE} kpt package"
print_and_execute "${KPT_BINARY} pkg get https://github.com/GoogleCloudPlatform/anthos-service-mesh-packages.git/asm@release-${ASM_RELEASE}-asm ${ASM_KPT_DIR}"

title_no_wait "Enable APIs"
print_and_execute "gcloud services enable --project ${PLATFORM_PROJECT_ID} \
anthos.googleapis.com \
cloudtrace.googleapis.com \
cloudresourcemanager.googleapis.com \
container.googleapis.com \
compute.googleapis.com \
gkeconnect.googleapis.com \
gkehub.googleapis.com \
iam.googleapis.com \
iamcredentials.googleapis.com \
logging.googleapis.com \
meshca.googleapis.com \
meshtelemetry.googleapis.com \
meshconfig.googleapis.com \
monitoring.googleapis.com \
stackdriver.googleapis.com \
sts.googleapis.com"

title_no_wait "Create the istiod-service.yaml file"
cat <<EOF > ${ASM_TEMP_DIR}/istiod-service.yaml
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

export KUBECONFIG=$(ls -1 ${BMCTL_WORKSPACE_DIR}/*/*-kubeconfig | tr '\n' ':')
for cluster_name in $(get_cluster_names); do
    load_cluster_config ${cluster_name}

    title_no_wait "Initialize the mesh configuration"
    IDENTITY_PROVIDER="$(kubectl --context=${cluster_name} get memberships.hub.gke.io membership -o=jsonpath='{.spec.identity_provider}')"    

    IDENTITY="$(echo "${IDENTITY_PROVIDER}" | sed 's/^https:\/\/gkehub.googleapis.com\/projects\/\(.*\)\/locations\/global\/memberships\/\(.*\)$/\1 \2/g')"

    read FLEET_PROJECT_ID HUB_MEMBERSHIP_ID <<< ${IDENTITY}

    POST_DATA='{"workloadIdentityPools":["'${FLEET_PROJECT_ID}'.hub.id.goog","'${FLEET_PROJECT_ID}'.svc.id.goog"]}'

    print_and_execute "curl --fail --output /dev/null --show-error --silent --request POST --header \"Content-Type: application/json\" --header \"Authorization: Bearer $(gcloud auth print-access-token)\" --data '${POST_DATA}' https://meshconfig.googleapis.com/v1alpha1/projects/${FLEET_PROJECT_ID}:initialize"

    title_no_wait "Configure the installation"
    FLEET_PROJECT_NUMBER=$(gcloud projects describe "${FLEET_PROJECT_ID}" --format="value(projectNumber)")

    CLUSTER_NAME="${HUB_MEMBERSHIP_ID}"

    CLUSTER_LOCATION="global"

    HUB_IDP_URL="$(kubectl --context=${cluster_name} get memberships.hub.gke.io membership -o=jsonpath='{.spec.identity_provider}')"

    cd ${ASM_TEMP_DIR}
    ${KPT_BINARY} cfg set ${ASM_KPT_DIR} gcloud.core.project ${FLEET_PROJECT_ID}
    ${KPT_BINARY} cfg set ${ASM_KPT_DIR} gcloud.container.cluster ${CLUSTER_NAME}
    ${KPT_BINARY} cfg set ${ASM_KPT_DIR} gcloud.compute.location ${CLUSTER_LOCATION}
    ${KPT_BINARY} cfg set ${ASM_KPT_DIR} anthos.servicemesh.hub gcr.io/gke-release/asm
    ${KPT_BINARY} cfg set ${ASM_KPT_DIR} anthos.servicemesh.rev ${ASM_REVISION}
    ${KPT_BINARY} cfg set ${ASM_KPT_DIR} anthos.servicemesh.tag ${ASM_VERSION}
    ${KPT_BINARY} cfg set ${ASM_KPT_DIR} gcloud.project.environProjectNumber ${FLEET_PROJECT_NUMBER}
    ${KPT_BINARY} cfg set ${ASM_KPT_DIR} anthos.servicemesh.hubTrustDomain ${FLEET_PROJECT_ID}.svc.id.goog
    ${KPT_BINARY} cfg set ${ASM_KPT_DIR} anthos.servicemesh.hub-idp-url "${HUB_IDP_URL}"  

    title_no_wait "Install Anthos Service Mesh"    
    print_and_execute "${ASM_INSTALL_DIR}/bin/istioctl install --context=${cluster_name} -f ${ASM_KPT_DIR}/istio/istio-operator.yaml -f ${ASM_KPT_DIR}/istio/options/hub-meshca.yaml --revision=${ASM_REVISION} --skip-confirmation"

    title_no_wait "Configuring the validating webhook"
    print_and_execute "kubectl --context=${cluster_name} apply -f ${ASM_TEMP_DIR}/istiod-service.yaml"
done

check_local_error
total_runtime
exit ${local_error}
