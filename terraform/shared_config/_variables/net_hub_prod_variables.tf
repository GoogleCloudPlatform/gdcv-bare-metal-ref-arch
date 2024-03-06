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

variable "google_project_id_net_hub_prod" {
  type        = string
  description = "The Google Cloud project ID for the production networking hub"

  validation {
    condition     = can(regex("^[a-z][-a-z0-9]{4,28}[a-z0-9]{1}$", var.google_project_id_net_hub_prod))
    error_message = "Google Cloud Project ID must be 6 to 30 characters in length and can only contain lowercase letters, numbers, and hyphens"
  }
}

variable "google_region_net_hub_prod" {
  description = "The Google Cloud default region for the production networking hub"
  type        = string
}

variable "google_vpc_network_name_net_hub_prod" {
  description = "The VPC network name for he production networking hub"
  type        = string
}
