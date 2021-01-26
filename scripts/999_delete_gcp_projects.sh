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

title_no_wait "Delete application project '${APP_PROJECT_ID}'"
print_and_execute "gcloud compute shared-vpc associated-projects remove ${APP_PROJECT_ID} --host-project ${NETWORK_PROJECT_ID}"
print_and_execute "gcloud projects delete --quiet ${APP_PROJECT_ID}"

title_no_wait "Delete platform project '${PLATFORM_PROJECT_ID}'"
print_and_execute "gcloud compute shared-vpc associated-projects remove ${PLATFORM_PROJECT_ID} --host-project ${NETWORK_PROJECT_ID}"
print_and_execute "gcloud projects delete --quiet ${PLATFORM_PROJECT_ID}"

title_no_wait "Delete network project '${NETWORK_PROJECT_ID}'"
print_and_execute "gcloud compute shared-vpc disable ${NETWORK_PROJECT_ID}"
print_and_execute "gcloud projects delete --quiet ${NETWORK_PROJECT_ID}"

check_local_error
total_runtime
exit ${local_error}
