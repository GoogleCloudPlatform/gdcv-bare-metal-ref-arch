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

snap_installed=`which snap`
if [ ! -z ${snap_installed} ]; then
    title_no_wait "Remove existing google-cloud-sdk snap packages"
    nopv_and_execute "sudo snap remove google-cloud-sdk 2> /dev/null"
fi

TEMP_DIR=${ABM_WORK_DIR}/tmp
mkdir -p ${TEMP_DIR}

cd ${TEMP_DIR}

title_no_wait "Checking DEPLOYMENT_USER"
bold_no_wait "DEPLOYMENT_USER is ${DEPLOYMENT_USER}"

if id "${DEPLOYMENT_USER}" &>/dev/null; then
    bold_no_wait "${DEPLOYMENT_USER} user found"
else
    error_no_wait "${DEPLOYMENT_USER} user NOT found, exiting!"
    exit -1
fi

GCLOUD_CMD=/usr/local/share/google-cloud-sdk/bin/gcloud
if [ ! -f ${GCLOUD_CMD} ]; then
    title_no_wait "Install Cloud SDK v${CLOUD_SDK_VERSION}_x86-64"
    
    bold_no_wait "Download google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz"
    print_and_execute "curl --output google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz"
    
    bold_no_wait "Install google-cloud-sdk"
    print_and_execute "sudo tar xf google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz -C /usr/local/share/"
    grep -q "google-cloud-sdk/path.bash.inc" /etc/bash.bashrc || echo -e "\n# The next line updates PATH for the Google Cloud SDK.\nif [ -f '/usr/local/share/google-cloud-sdk/path.bash.inc' ]; then . '/usr/local/share/google-cloud-sdk/path.bash.inc'; fi" | sudo tee -a /etc/bash.bashrc 1> /dev/null
    sudo ln -s -f /usr/local/share/google-cloud-sdk/completion.bash.inc /etc/bash_completion.d/gcloud
    . '/usr/local/share/google-cloud-sdk/path.bash.inc'
    
    title_no_wait "Install gcloud components"
    print_and_execute "sudo ${GCLOUD_CMD} components install -q alpha beta kpt kubectl"
    sudo sh -c "/usr/local/share/google-cloud-sdk/bin/kubectl completion bash > /etc/bash_completion.d/kubectl"
fi

title_no_wait "Install krew for kubectl"
print_and_execute "curl -fsSLO https://github.com/kubernetes-sigs/krew/releases/latest/download/krew.tar.gz"
print_and_execute "tar xfz  krew.tar.gz"
KREW=./krew-"$(uname | tr '[:upper:]' '[:lower:]')_$(uname -m | sed -e 's/x86_64/amd64/' -e 's/arm.*$/arm/')"
PATH=${PATH}:\${HOME}/.krew/bin
print_and_execute "${KREW} install krew"
print_and_execute "${KREW} update"

grep -q "/.krew/bin" ~/.bashrc || echo -e "export PATH=\${PATH}:\${HOME}/.krew/bin" >> ~/.bashrc
PATH=${PATH}:${HOME}/.krew/bin

title_no_wait "Install ctx plugin"
print_and_execute "/usr/local/share/google-cloud-sdk/bin/kubectl krew install ctx"

title_no_wait "Install ns plugin"
print_and_execute "/usr/local/share/google-cloud-sdk/bin/kubectl krew install ns"

title_no_wait "Install Docker"
sudo apt-get update
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
"deb [arch=amd64] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) \
stable"
sudo apt-get update

print_and_execute "sudo apt-get install -y docker-ce docker-ce-cli containerd.io"

#curl -fsSL https://get.docker.com -o get-docker.sh
#sudo sh get-docker.sh

print_and_execute "sudo usermod -aG docker $USER"

title_no_wait "Install kind v${KIND_VERSION} binary"
print_and_execute "mkdir -p ~/bin"
print_and_execute "curl --location --output ~/bin/kind https://github.com/kubernetes-sigs/kind/releases/download/v${KIND_VERSION}/kind-linux-amd64"
print_and_execute "chmod u+x ~/bin/kind"

title_no_wait "Check ${DEPLOYMENT_USER} user's SSH key"
if sudo [ ! -f "${DEPLOYMENT_USER_SSH_KEY}" ]; then
    bold_no_wait "Generating SSH key at '${DEPLOYMENT_USER_SSH_KEY}'"
    sudo -H -u ${DEPLOYMENT_USER} ssh-keygen -f ${DEPLOYMENT_USER_SSH_KEY} -N '' -t rsa
else
    bold_no_wait "SSH key already exists at '${DEPLOYMENT_USER_SSH_KEY}'"
fi

mkdir -p ${ABM_WORK_DIR}/keys

sudo cp ${DEPLOYMENT_USER_SSH_KEY} ${ABM_WORK_DIR}/keys/id_rsa
sudo chown ${USER}:${USER} ${ABM_WORK_DIR}/keys/id_rsa

check_local_error
total_runtime
exit ${local_error}
