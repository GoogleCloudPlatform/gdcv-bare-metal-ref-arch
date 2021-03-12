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

#compute_required_cpus () {
#    # TODO: Implement
#}
#export -f compute_required_cpus

get_cluster_conf_files () {
    echo $(find ${ABM_WORK_DIR}/conf -maxdepth 1 -type f | egrep -v '/global$' | sort)
}
export -f get_cluster_conf_files

get_cluster_names () {
    conf_files=$(get_cluster_conf_files)
    echo ${conf_files} |  sed -e "s|${ABM_CONF_DIR}/||g"
}
export -f get_cluster_names

get_conf_files () {
    echo $(find ${ABM_WORK_DIR}/conf -maxdepth 1 -type f | sort)
}
export -f get_conf_files

get_control_plane_node_addresses () {
    echo $(env | egrep 'CP_[0-9]+_IP=' | awk -F= '{print $2}')
}
export -f get_control_plane_node_addresses

get_number_of_control_plane_nodes () {
    echo $(env | egrep 'CP_[0-9]+_IP=' | wc -l)
}
export -f get_number_of_control_plane_nodes

get_number_of_worker_nodes () {
    echo $(env | egrep 'WORKER_[0-9]+_IP=' | wc -l)
}
export -f get_number_of_worker_nodes

get_worker_node_addresses () {
    echo $(env | egrep 'WORKER_[0-9]+_IP=' | awk -F= '{print $2}')
}
export -f get_worker_node_addresses

load_additional_config() {
    cluster_name=${1}

    if [ ! -z "${ABM_ADDITIONAL_CONF}" ]; then
        source ${ABM_CONF_DIR}/${ABM_ADDITIONAL_CONF}/global
        source ${ABM_CONF_DIR}/${ABM_ADDITIONAL_CONF}/${cluster_name}
    fi
}
export -f load_additional_config

load_cluster_config () {
    cluster_name=${1}

    unset_config

    if [[ ! $(get_cluster_names) =~ ${cluster_name} ]]; then
        echo "No configuration found for cluster '$1'"
        exit -1
    fi

    source ${ABM_CONF_DIR}/global
    source ${ABM_CONF_DIR}/${cluster_name}

    load_additional_config ${cluster_name}

    export CLUSTER_NAME=${cluster_name}
}
export -f load_cluster_config

load_global_config () {
    unset_config

    source ${ABM_CONF_DIR}/global
    if [ ! -z "${ABM_ADDITIONAL_CONF}" ]; then
        source ${ABM_CONF_DIR}/${ABM_ADDITIONAL_CONF}/global
    fi
}
export -f load_global_config

unset_config () {
    conf_variables=`cat $(get_conf_files) | egrep "^export" | awk 'BEGIN{FS="[= ]"}{print $2}' | sort | uniq`
    conf_variables+=" CLUSTER_NAME"    
    for variable in ${conf_variables}; do
        unset ${variable}
    done
}
export -f unset_config
