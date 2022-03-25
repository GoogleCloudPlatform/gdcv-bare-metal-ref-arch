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

export start_timestamp=`date +%s`

source ${ABM_WORK_DIR}/scripts/helpers/configuration.sh
source ${ABM_WORK_DIR}/scripts/helpers/functions.sh

pv_installed=`which pv`
if [ -z ${pv_installed} ]; then
    title_no_wait "Install pv"
    nopv_and_execute "sudo apt-get update && sudo apt-get -y install pv"
fi

export ENVIRONMENT_FILE=${ABM_WORK_DIR}/scripts/vars.sh
touch ${ENVIRONMENT_FILE}

source ${ABM_WORK_DIR}/scripts/helpers/environment.sh

source ${ENVIRONMENT_FILE}

# Create a logs folder and file and send stdout and stderr to console and log file
mkdir -p ${ABM_WORK_DIR}/logs
export LOG_FILE=${ABM_WORK_DIR}/logs/${LOG_FILE_PREFIX}$(basename $0)-$(date +%s).log
touch ${LOG_FILE}
exec 2>&1
exec &> >(tee -i ${LOG_FILE})

VALID_CHARACTERS="[:alnum:]_/\.\-"

grep -q "export ABM_ADDITIONAL_CONF=" ${ENVIRONMENT_FILE} || echo -e "export ABM_ADDITIONAL_CONF=${ABM_ADDITIONAL_CONF:-}" >> ${ENVIRONMENT_FILE}
grep -q "export ABM_WORK_DIR=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export ABM_WORK_DIR=${ABM_WORK_DIR}" >> ${ENVIRONMENT_FILE}
grep -q "export APP_NAMESPACE=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export APP_NAMESPACE=${APP_NAMESPACE:-bofa}" >> ${ENVIRONMENT_FILE}
grep -q "export APP_PROJECT_ID=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export APP_PROJECT_ID=${APP_PROJECT_ID:-project-2-bofa-prod}" >> ${ENVIRONMENT_FILE}
grep -q "export ASM_GATEWAY_NAMESPACE=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export ASM_GATEWAY_NAMESPACE=${ASM_GATEWAY_NAMESPACE:-asm-gateway}" >> ${ENVIRONMENT_FILE}
grep -q "export ASM_VERSION_MAJOR=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export ASM_VERSION_MAJOR=${ASM_VERSION_MAJOR:-1}" >> ${ENVIRONMENT_FILE}
grep -q "export ASM_VERSION_MINOR=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export ASM_VERSION_MINOR=${ASM_VERSION_MINOR:-12}" >> ${ENVIRONMENT_FILE}
grep -q "export ASM_VERSION_POINT=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export ASM_VERSION_POINT=${ASM_VERSION_POINT:-5}" >> ${ENVIRONMENT_FILE}
grep -q "export ASM_VERSION_REV=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export ASM_VERSION_REV=${ASM_VERSION_REV:-0}" >> ${ENVIRONMENT_FILE}
grep -q "export ASM_VERSION_CONFIG=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export ASM_VERSION_CONFIG=${ASM_VERSION_CONFIG:-1}" >> ${ENVIRONMENT_FILE}
grep -q "export BILLING_ACCOUNT_ID=" ${ENVIRONMENT_FILE} || echo -e "export BILLING_ACCOUNT_ID=${BILLING_ACCOUNT_ID}" >> ${ENVIRONMENT_FILE}
grep -q "export BMCTL_VERSION=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export BMCTL_VERSION=${BMCTL_VERSION:-1.10.2}" >> ${ENVIRONMENT_FILE}
grep -q "export CLOUD_OPS_REGION=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export CLOUD_OPS_REGION=${CLOUD_OPS_REGION:-global}" >> ${ENVIRONMENT_FILE}
grep -q "export CLOUD_SDK_VERSION=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export CLOUD_SDK_VERSION=${CLOUD_SDK_VERSION:-378.0.0}" >> ${ENVIRONMENT_FILE}
grep -q "export DEPLOYMENT_USER=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || (echo -e "export DEPLOYMENT_USER=${DEPLOYMENT_USER:-anthos}" >> ${ENVIRONMENT_FILE} && source ${ENVIRONMENT_FILE})
grep -q "export FOLDER_ID=" ${ENVIRONMENT_FILE} || echo -e "export FOLDER_ID=${FOLDER_ID:-}" >> ${ENVIRONMENT_FILE}
grep -q "export KIND_VERSION=" ${ENVIRONMENT_FILE} || echo -e "export KIND_VERSION=${KIND_VERSION:-0.11.1}" >> ${ENVIRONMENT_FILE}
grep -q "export KUSTOMIZATION_TYPE=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export KUSTOMIZATION_TYPE=${KUSTOMIZATION_TYPE:-hybrid}" >> ${ENVIRONMENT_FILE}
grep -q "export NETWORK_PROJECT_ID=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export NETWORK_PROJECT_ID=${NETWORK_PROJECT_ID:-project-0-net-prod}" >> ${ENVIRONMENT_FILE}
grep -q "export ORGANIZATION_ID=" ${ENVIRONMENT_FILE} || echo -e "export ORGANIZATION_ID=${ORGANIZATION_ID:-}" >> ${ENVIRONMENT_FILE}
grep -q "export PLATFORM_PROJECT_ID=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export PLATFORM_PROJECT_ID=${PLATFORM_PROJECT_ID:-project-1-platform-prod}" >> ${ENVIRONMENT_FILE}
grep -q "export USE_SHARED_VPC=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export USE_SHARED_VPC=${USE_SHARED_VPC:-true}" >> ${ENVIRONMENT_FILE}

source ${ENVIRONMENT_FILE}

# Variable with dependencies above
grep -q "export ABM_CONF_DIR=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export ABM_CONF_DIR=${ABM_CONF_DIR:-${ABM_WORK_DIR}/conf}" >> ${ENVIRONMENT_FILE}
grep -q "export ACM_REPO_DIRECTORY=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export ACM_REPO_DIRECTORY=${ACM_REPO_DIRECTORY:-${ABM_WORK_DIR}/acm}" >> ${ENVIRONMENT_FILE}
grep -q "export ASM_REV_LABEL=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export ASM_REV_LABEL=${ASM_REV_LABEL:-asm-${ASM_VERSION_MAJOR}${ASM_VERSION_MINOR}${ASM_VERSION_POINT}-${ASM_VERSION_REV}}" >> ${ENVIRONMENT_FILE}
grep -q "export BMCTL_WORKSPACE_DIR=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export BMCTL_WORKSPACE_DIR=${BMCTL_WORKSPACE_DIR:-${ABM_WORK_DIR}/bmctl-workspace}" >> ${ENVIRONMENT_FILE}

if [[ ${ADMIN_WORKSTATION_PREPARED} == "true" ]]; then
    grep -q "export PLATFORM_PROJECT_NUMBER=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export PLATFORM_PROJECT_NUMBER=${PLATFORM_PROJECT_NUMBER:-$(gcloud projects describe ${PLATFORM_PROJECT_ID} --format='value(projectNumber)')}" >> ${ENVIRONMENT_FILE}
    
    source ${ENVIRONMENT_FILE}

    grep -q "export ASM_MESH_ID=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export ASM_MESH_ID=${ASM_MESH_ID:-proj-${PLATFORM_PROJECT_NUMBER}}" >> ${ENVIRONMENT_FILE}
fi

source ${ENVIRONMENT_FILE}

DEPLOYMENT_USER_HOME=`eval echo "~${DEPLOYMENT_USER}"`
if [[ ! ${DEPLOYMENT_USER_HOME} = ~* ]] || [ ! -z ${DEPLOYMENT_USER_SSH_KEY} ]; then
    grep -q "export DEPLOYMENT_USER_SSH_KEY=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export DEPLOYMENT_USER_SSH_KEY=${DEPLOYMENT_USER_SSH_KEY:-${DEPLOYMENT_USER_HOME}/.ssh/id_rsa}" >> ${ENVIRONMENT_FILE}
fi

sort -o ${ENVIRONMENT_FILE} ${ENVIRONMENT_FILE}
source ${ENVIRONMENT_FILE}

# Add environment file to .profile file
grep -q "${ENVIRONMENT_FILE}" ~/.profile || echo -e "source ${ENVIRONMENT_FILE}" >> ~/.profile

local_error=0
