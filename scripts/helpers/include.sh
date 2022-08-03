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

set_environment_variable_skip_if_existing "ABM_ADDITIONAL_CONF=${ABM_ADDITIONAL_CONF:-}"
set_environment_variable_skip_if_existing "ABM_WORK_DIR=${ABM_WORK_DIR}"
set_environment_variable_skip_if_existing "APP_NAMESPACE=${APP_NAMESPACE:-bofa}"
set_environment_variable_skip_if_existing "APP_PROJECT_ID=${APP_PROJECT_ID:-project-2-bofa-prod}"
set_environment_variable_skip_if_existing "ASM_GATEWAY_NAMESPACE=${ASM_GATEWAY_NAMESPACE:-asm-gateway}"
set_environment_variable_skip_if_existing "ASM_VERSION_MAJOR=${ASM_VERSION_MAJOR:-1}"
set_environment_variable_skip_if_existing "ASM_VERSION_MINOR=${ASM_VERSION_MINOR:-14}"
set_environment_variable_skip_if_existing "ASM_VERSION_POINT=${ASM_VERSION_POINT:-1}"
set_environment_variable_skip_if_existing "ASM_VERSION_REV=${ASM_VERSION_REV:-3}"
set_environment_variable_skip_if_existing "ASM_VERSION_CONFIG=${ASM_VERSION_CONFIG:-1}"
set_environment_variable_skip_if_existing "BILLING_ACCOUNT_ID=${BILLING_ACCOUNT_ID}"
set_environment_variable_skip_if_existing "BMCTL_VERSION=${BMCTL_VERSION:-1.12.1}"
set_environment_variable_skip_if_existing "CLOUD_OPS_REGION=${CLOUD_OPS_REGION:-global}"
set_environment_variable_skip_if_existing "CLOUD_SDK_VERSION=${CLOUD_SDK_VERSION:-394.0.0}"
set_environment_variable_skip_if_existing "DEPLOYMENT_USER=${DEPLOYMENT_USER:-anthos}"
set_environment_variable_skip_if_existing "FOLDER_ID=${FOLDER_ID:-}"
set_environment_variable_skip_if_existing "KIND_VERSION=${KIND_VERSION:-0.11.1}"
set_environment_variable_skip_if_existing "KUSTOMIZATION_TYPE=${KUSTOMIZATION_TYPE:-hybrid}"
set_environment_variable_skip_if_existing "NETWORK_PROJECT_ID=${NETWORK_PROJECT_ID:-project-0-net-prod}"
set_environment_variable_skip_if_existing "ORGANIZATION_ID=${ORGANIZATION_ID:-}"
set_environment_variable_skip_if_existing "PLATFORM_PROJECT_ID=${PLATFORM_PROJECT_ID:-project-1-platform-prod}"
set_environment_variable_skip_if_existing "USE_SHARED_VPC=${USE_SHARED_VPC:-true}"

# Variable with dependencies above
set_environment_variable_skip_if_existing "ABM_CONF_DIR=${ABM_CONF_DIR:-${ABM_WORK_DIR}/conf}"
set_environment_variable_skip_if_existing "ACM_REPO_DIRECTORY=${ACM_REPO_DIRECTORY:-${ABM_WORK_DIR}/acm}"
set_environment_variable_skip_if_existing "ASM_REV_LABEL=${ASM_REV_LABEL:-asm-${ASM_VERSION_MAJOR}${ASM_VERSION_MINOR}${ASM_VERSION_POINT}-${ASM_VERSION_REV}}"
set_environment_variable_skip_if_existing "BMCTL_WORKSPACE_DIR=${BMCTL_WORKSPACE_DIR:-${ABM_WORK_DIR}/bmctl-workspace}"

if [[ ${ADMIN_WORKSTATION_PREPARED} == "true" ]]; then
    set_environment_variable_skip_if_existing "PLATFORM_PROJECT_NUMBER=${PLATFORM_PROJECT_NUMBER:-$(gcloud projects describe ${PLATFORM_PROJECT_ID} --format='value(projectNumber)')}"
    set_environment_variable_skip_if_existing "ASM_MESH_ID=${ASM_MESH_ID:-proj-${PLATFORM_PROJECT_NUMBER}}"
fi

DEPLOYMENT_USER_HOME=`eval echo "~${DEPLOYMENT_USER}"`
if [[ ! ${DEPLOYMENT_USER_HOME} = ~* ]] || [ ! -z ${DEPLOYMENT_USER_SSH_KEY} ]; then
    set_environment_variable_skip_if_existing "DEPLOYMENT_USER_SSH_KEY=${DEPLOYMENT_USER_SSH_KEY:-${DEPLOYMENT_USER_HOME}/.ssh/id_rsa}"
fi

sort -o ${ENVIRONMENT_FILE}{,}

# Check for duplicates
duplicates=$(awk -F' |=' '{print $2}' ${ENVIRONMENT_FILE} | uniq -c | egrep -v '^[[:blank:]]*1' | awk '{print $2}')
if [[ "${duplicates}" != "" ]]; then
    echo "[ERROR] Duplicate entries found in ${ENVIRONMENT_FILE}"
    echo "----------------------------------------------------------------"
    for dup in ${duplicates}; do
        grep ${dup} ${ENVIRONMENT_FILE}
    done
    echo "----------------------------------------------------------------"
    echo "Fixed any duplicates and retry the script, exiting!"
    echo

    exit -1
fi

source ${ENVIRONMENT_FILE}

# Add environment file to .profile file
grep -q "${ENVIRONMENT_FILE}" ~/.profile || echo -e "source ${ENVIRONMENT_FILE}" >> ~/.profile

local_error=0
