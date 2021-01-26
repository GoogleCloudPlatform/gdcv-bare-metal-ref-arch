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

bold=$(tput bold)
normal=$(tput sgr0)

CYAN='\033[1;36m'
GREEN='\e[1;32m'
NC='\e[0m'
RED='\e[1;91m'
YELLOW="\e[38;5;226m"

bold_and_wait () {
    echo
    echo "${bold}${@}"
    echo -e "${YELLOW}--> Press ENTER to continue...${NC}"
    read -p ''
}
export -f bold_and_wait

bold_no_wait () {
    echo "${bold}${@}${normal}"
}
export -f bold_no_wait

check_local_error () {
    printf "\n"
    if [ ${local_error} -ne 0 ]; then
        error_no_wait "There was an error while executing the script, review the output."
    fi
    
    if [ ! -z ${LOG_FILE} ]; then
        bold_no_wait "A log file is available at '${LOG_FILE}'"
    fi
    printf "\n"
}
export -f check_local_error

error_no_wait () {
    printf "${RED}${@}${NC}"
    printf "\n"
}
export -f error_no_wait

nopv_and_execute () {
    printf "${GREEN}\$ ${@}${NC}"
    printf "\n"
    eval "$@"
    return_code=$?
    if [ ${return_code} -eq "0" ]; then
        success_no_wait "[OK]"
    else
        error_no_wait "[Return Code: ${return_code}]"
        local_error=$(($local_error+1))
    fi
    printf "\n"
    return ${return_code}
}
export -f nopv_and_execute

nopv_and_execute_no_status () {
    printf "${GREEN}\$ ${@}${NC}"
    printf "\n"
    eval "$@"
    return_code=$?
    if [ ${return_code} -ne "0" ]; then
        local_error=$(($local_error+1))
    fi
    printf "\n"
    return ${return_code}
}
export -f nopv_and_execute_no_status

print_and_execute () {
    SPEED=290
    
    printf "${GREEN}\$ ${@}${NC}" | pv -qL $SPEED;
    printf "\n"
    eval "$@"
    return_code=$?
    if [ ${return_code} -eq "0" ]; then
        success_no_wait "[OK]"
    else
        error_no_wait "[Return Code: ${return_code}]"
        local_error=$(($local_error+1))
    fi
    printf "\n"
    return ${return_code}
}
export -f print_and_execute

print_and_execute_no_status () {
    SPEED=290
    
    printf "${GREEN}\$ ${@}${NC}" | pv -qL $SPEED;
    printf "\n"
    eval "$@"
    return_code=$?
    if [ ${return_code} -ne "0" ]; then
        local_error=$(($local_error+1))
    fi
    printf "\n"
    return ${return_code}
}
export -f print_and_execute_no_status

success_no_wait () {
    printf "${GREEN}${@}${NC}"
    printf "\n"
}
export -f error_no_wait

title_and_wait () {
    echo
    echo "${bold}# ${@}"
    echo -e "${YELLOW}--> Press ENTER to continue...${NC}"
    read -p ''
}
export -f title_and_wait

title_no_wait () {
    echo
    echo "${bold}# ${@}${normal}"
}
export -f title_no_wait

total_runtime () {
    if [ ! -z ${start_timestamp} ]; then
        end_timestamp=`date +%s`
        runtime=$((end_timestamp-start_timestamp))
        bold_no_wait "Total runtime: `date -d@${runtime} -u +%H:%M:%S`"
    fi
}
export -f total_runtime
