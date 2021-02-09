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

export start_timestamp=`date +%s`

source ${ABM_WORK_DIR}/scripts/helpers/functions.sh

pv_installed=`which pv`
if [ -z ${pv_installed} ]; then
    title_no_wait "Install pv"
    nopv_and_execute "sudo apt-get update && sudo apt-get -y install pv"
fi

export ENVIRONMENT_FILE=${ABM_WORK_DIR}/scripts/vars.sh
touch ${ENVIRONMENT_FILE}

source ${ENVIRONMENT_FILE}

# Create a logs folder and file and send stdout and stderr to console and log file
mkdir -p ${ABM_WORK_DIR}/logs
export LOG_FILE=${ABM_WORK_DIR}/logs/${LOG_FILE_PREFIX}$(basename $0)-$(date +%s).log
touch ${LOG_FILE}
exec 2>&1
exec &> >(tee -i ${LOG_FILE})

declare -a CLUSTER_NAME
CLUSTER_NAME=(
    ["1"]="metal-1-apps-dc1a-prod"
    ["2"]="metal-2-apps-dc1b-prod"
    ["3"]="metal-3-apps-dc2a-prod"
    ["4"]="metal-4-apps-dc2b-prod"
)

declare -a IP_PREFIX
IP_PREFIX=(
    ["1"]="10.185.1"
    ["2"]="10.185.2"
    ["3"]="10.195.1"
    ["4"]="10.195.2"
)

declare -a REGION
REGION=(
    ["1"]="us-central1"
    ["2"]="us-central1"
    ["3"]="us-west1"
    ["4"]="us-west1"
)

declare -a ZONE
ZONE=(
    ["1"]="us-central1-a"
    ["2"]="us-central1-b"
    ["3"]="us-west1-a"
    ["4"]="us-west1-b"
)

NUM_CLUSTERS=${NUM_CLUSTERS:-4}
NUM_CP_NODES=${NUM_CP_NODES:-3}
NUM_WORKER_NODES=${NUM_WORKER_NODES:-3}

VALID_CHARACTERS="[:alnum:]_/\.\-"

grep -q "export ABM_WORK_DIR=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export ABM_WORK_DIR=${ABM_WORK_DIR}" >> ${ENVIRONMENT_FILE}
grep -q "export APP_NAMESPACE=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export APP_NAMESPACE=${APP_NAMESPACE:-bofa}" >> ${ENVIRONMENT_FILE}
grep -q "export APP_PROJECT_ID=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export APP_PROJECT_ID=${APP_PROJECT_ID:-project-2-bofa-prod}" >> ${ENVIRONMENT_FILE}
grep -q "export ASM_VERSION=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export ASM_VERSION=${ASM_VERSION:-1.7.6-asm.1}" >> ${ENVIRONMENT_FILE}
grep -q "export ASM_REVISION=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export ASM_REVISION=${ASM_REVISION:-asm-176-1}" >> ${ENVIRONMENT_FILE}
grep -q "export BILLING_ACCOUNT_ID=" ${ENVIRONMENT_FILE} || echo -e "export BILLING_ACCOUNT_ID=${BILLING_ACCOUNT_ID}" >> ${ENVIRONMENT_FILE}
grep -q "export BMCTL_VERSION=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export BMCTL_VERSION=${BMCTL_VERSION:-1.6.1}" >> ${ENVIRONMENT_FILE}
grep -q "export CLOUD_OPS_REGION=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export CLOUD_OPS_REGION=${CLOUD_OPS_REGION:-global}" >> ${ENVIRONMENT_FILE}
grep -q "export CLOUD_SDK_VERSION=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export CLOUD_SDK_VERSION=${CLOUD_SDK_VERSION:-326.0.0}" >> ${ENVIRONMENT_FILE}
grep -q "export DEPLOYMENT_USER=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || (echo -e "export DEPLOYMENT_USER=${DEPLOYMENT_USER:-anthos}" >> ${ENVIRONMENT_FILE} && source ${ENVIRONMENT_FILE})
grep -q "export FOLDER_ID=" ${ENVIRONMENT_FILE} || echo -e "export FOLDER_ID=${FOLDER_ID:-}" >> ${ENVIRONMENT_FILE}
grep -q "export NETWORK_NAME=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export NETWORK_NAME=${NETWORK_NAME:-default}" >> ${ENVIRONMENT_FILE}
grep -q "export NETWORK_PROJECT_ID=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export NETWORK_PROJECT_ID=${NETWORK_PROJECT_ID:-project-0-net-prod}" >> ${ENVIRONMENT_FILE}
grep -q "export ORGANIZATION_ID=" ${ENVIRONMENT_FILE} || echo -e "export ORGANIZATION_ID=${ORGANIZATION_ID:-}" >> ${ENVIRONMENT_FILE}
grep -q "export PLATFORM_PROJECT_ID=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export PLATFORM_PROJECT_ID=${PLATFORM_PROJECT_ID:-project-1-platform-prod}" >> ${ENVIRONMENT_FILE}
grep -q "export USE_SHARED_VPC=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export USE_SHARED_VPC=${USE_SHARED_VPC:-true}" >> ${ENVIRONMENT_FILE}

source ${ENVIRONMENT_FILE}

# Variable with dependencies above
DEPLOYMENT_USER_HOME=`eval echo "~${DEPLOYMENT_USER}"`
if [[ ! ${DEPLOYMENT_USER_HOME} = ~* ]] || [ ! -z ${DEPLOYMENT_USER_SSH_KEY} ]; then
    grep -q "export DEPLOYMENT_USER_SSH_KEY=[${VALID_CHARACTERS}]\+$" ${ENVIRONMENT_FILE} || echo -e "export DEPLOYMENT_USER_SSH_KEY=${DEPLOYMENT_USER_SSH_KEY:-${DEPLOYMENT_USER_HOME}/.ssh/id_rsa}" >> ${ENVIRONMENT_FILE}
fi

sort -o ${ENVIRONMENT_FILE} ${ENVIRONMENT_FILE}
source ${ENVIRONMENT_FILE}

HOSTS_FILE=${ABM_WORK_DIR}/scripts/hosts.sh
if [ -f ${HOSTS_FILE} ]; then
    source ${HOSTS_FILE}
fi

# Add environment file to .profile file
grep -q "${ENVIRONMENT_FILE}" ~/.profile || echo -e "source ${ENVIRONMENT_FILE}" >> ~/.profile

local_error=0
