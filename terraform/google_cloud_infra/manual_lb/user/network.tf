# Copyright 2023 Google LLC
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

locals {
  gdcv_network_name = data.google_compute_network.gdcv_prod.name
}

data "google_compute_network" "gdcv_prod" {
  name    = var.google_vpc_network_name_gdcv_on_gce_prod
  project = local.project_id_gdcv_on_gce_prod
}

data "google_netblock_ip_ranges" "health_checkers" {
  range_type = "health-checkers"
}

data "google_compute_health_check" "gdcv_cp_healthcheck" {
  name    = "gdcv-cp-healthcheck"
  project = local.project_id_gdcv_on_gce_prod
}
