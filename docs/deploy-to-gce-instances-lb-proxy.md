# Deploy to GCE instances with manual load balancers(Proxy load balancers)

## Google Cloud Platform(GCP) account requirements

See the [Logging into gcloud](https://cloud.google.com/anthos/clusters/docs/bare-metal/installing/install-prereq#logging_into_gcloud) section of the [Installation prerequisities overview](https://cloud.google.com/anthos/clusters/docs/bare-metal/installing/install-prereq) documentation for the IAM role requirements.

### Quota

The following quota limits are required in the PLATFORM_PROJECT_ID project to provision all of the instances with the default configuration:

| Service            | Limit name      | Dimensions (e.g location) | Limit |
|--------------------|-----------------|---------------------------|-------|
| Compute Engine API | N2 CPUs         | region: us-central1       | 100   |
| Compute Engine API | N2 CPUs         | region: us-west1          | 96    |

## Prepare Cloud Shell

1. Open Cloud Shell
1. **[Cloud Shell]** Authenticate `gcloud` and set the application-default
   ```
   gcloud auth login --activate --quiet --update-adc
   ```
1. **[Cloud Shell]** Clone this project to the Cloud Shell home directory
   ```
   git clone https://github.com/GoogleCloudPlatform/anthos-bare-metal-ref-arch.git
   ```
1. **[Cloud Shell]** Set the Organization ID or Folder ID where the projects will be created.
   > This step can be skipped if using existing projects.
   ```
   export ORGANIZATION_ID=
   ```
   **OR**
   ```
   export FOLDER_ID=
   ```
1. **[Cloud Shell]** Set the Billing Account ID of the Billing Account for the new projects.
   > This step can be skipped if using existing projects.
   ```
   export BILLING_ACCOUNT_ID=
   ```
1. **[Cloud Shell]** Set the Project IDs for the new or existing projects, if not set the following defaults will be used:
   ```
   export NETWORK_PROJECT_ID=project-0-net-prod
   export PLATFORM_PROJECT_ID=project-1-platform-prod
   export APP_PROJECT_ID=project-2-bofa-prod
   ```
1. **[Cloud Shell]** Enable additional configuration for GCE with manual load balancers
   ```
   export ABM_ADDITIONAL_CONF=gce
   export KUSTOMIZATION_TYPE=hybrid-manual-lb
   ```   
1. **[Cloud Shell]** Change directory into `anthos-bare-metal-ref-arch`
   ```
   cd anthos-bare-metal-ref-arch
   ```
1. **[Cloud Shell]** Setup variables file
   ```
   ./scripts/helpers/set_variables.sh
   ```
1. **[Cloud Shell]** Logout, the new shell configurations will take effect on next login
   ```
   logout
   ```

## Create the GCP projects

1. Open Cloud Shell
1. **[Cloud Shell]** Create the GCP projects
   ```
   ${ABM_WORK_DIR}/scripts/002_create_gcp_projects.sh
   ```

## Create the Shared VPC

To create the Shared VPC in the NETWORK_PROJECT_ID project, the `Compute Shared VPC Admin` role is required for the organization or folder.

1. Open Cloud Shell
1. **[Cloud Shell]** Create the Shared VPC
   ```
   ${ABM_WORK_DIR}/scripts/003_create_shared_vpc.sh
   ```

## Create the administrative host

1. Open Cloud Shell
1. **[Cloud Shell]** Create the administrative host
   ```
   ${ABM_WORK_DIR}/scripts/gcp/001_create_admin_instance.sh
   ```

## Prepare the administrative host

1. Connect to the administrative host
   - Preferred SSH client
   - CloudShell:
     ```
     gcloud compute ssh --project ${PLATFORM_PROJECT_ID} --zone=us-central1-a bare-metal-admin-1
     ```
1. **[Admin Host]** Clone this project to the administrative host
   ```
   git clone https://github.com/GoogleCloudPlatform/anthos-bare-metal-ref-arch.git
   ```
1. **[Admin Host]** Set the Project IDs for the projects, these should match the value entered above.
   ```
   export NETWORK_PROJECT_ID=project-0-net-prod
   export PLATFORM_PROJECT_ID=project-1-platform-prod
   export APP_PROJECT_ID=project-2-bofa-prod
   ```
1. **[Admin Host]** Enable additional configuration for GCE with manual load balancers
   ```
   export ABM_ADDITIONAL_CONF=gce
   export KUSTOMIZATION_TYPE=hybrid-manual-lb
   ```   
1. **[Admin Host]** Change directory into `anthos-bare-metal-ref-arch`
   ```
   cd anthos-bare-metal-ref-arch
   ```
1. **[Admin Host]** Setup variables file
   ```
   ./scripts/helpers/set_variables.sh
   ```
1. **[Admin Host]** Source the `vars.sh` file
   ```
   source ./scripts/vars.sh
   ```
1. **[Admin Host]** Prepare the administrative host
   ```
   ./scripts/001_prepare_admin_host.sh
   ```
1. **[Admin Host]** Logout, the new shell configurations will take effect on next login.
   ```
   logout
   ```

## Create the GCE instances

1. Connect to the administrative host
1. **[Admin Host]** Authenticate `gcloud` and set the application-default
   ```
   gcloud auth login --activate --quiet --update-adc
   ```
   > **NOTE**: If you get an error message such as: ` gcloud: command not found` or `-bash: /snap/bin/gcloud: No such file or directory`, logout to activate the shell configuration changes.
1. **[Admin Host]** Create the GCE cluster instances
   ```
   ${ABM_WORK_DIR}/scripts/gcp/002_create_cluster_instances.sh
   ```
1. **[Admin Host]** Distribute the `DEPLOYMENT_USER` SSH key
   ```
   ${ABM_WORK_DIR}/scripts/gcp/003_distribute_ssh_keys.sh
   ```
1. **[Admin Host]** Validate the `DEPLOYMENT_USER` settings
   ```
   ${ABM_WORK_DIR}/scripts/gcp/004_validate_deployment_user.sh
   ```

## Create the control plane load balancers

1. Connect to the administrative host
1. **[Admin Host]** Create the control plane load balancer
   ```
   ${ABM_WORK_DIR}/scripts/gcp/lb-proxy/001_create_cp_lb.sh
   ```
1. **[Admin Host]** Create the ingress load balancer address
   ```
   ${ABM_WORK_DIR}/scripts/gcp/lb-proxy/002_create_ingress_lb_address.sh
   ```

## Prepare the cluster configuration files

1. Connect to the administrative host
1. **[Admin Host]** Generate the configuration files
   ```
   ${ABM_WORK_DIR}/scripts/gcp/lb-proxy/003_generate_conf_files.sh
   ```
1. **[Admin Host]** Prepare the cluster configuration files
   ```
   ${ABM_WORK_DIR}/scripts/004_prepare_configuration_files.sh
   ```

## Create the clusters

1. Connect to the administrative host
1. **[Admin Host]** Create the clusters
   ```
   ${ABM_WORK_DIR}/scripts/005_create_clusters.sh
   ```

## Create the ingress load balancers

1. **[Admin Host]** Create the ingress load balancer
   ```
   ${ABM_WORK_DIR}/scripts/gcp/lb-proxy/004_create_ingress_lb.sh
   ```

## Login to the cluster with the Cloud Console

1. Connect to the administrative host
1. **[Admin Host]** Generate the cluster login tokens
   ```
   ${ABM_WORK_DIR}/scripts/006_generate_login_tokens.sh
   ```
1. Open the URL provided by the script
1. For each cluster:
   1. Click on the cluster name
   1. Click Login
   1. Choose Token as the method for authentication
   1. Paste the token from the `006_generate_login_tokens.sh` script for the associated cluster
   1. Click Login
1. Verify that all clusters show healthy

## Configure Anthos Config Management(ACM)

1. Connect to the administrative host
1. **[Admin Host]** Setup ACM
   ```
   ${ABM_WORK_DIR}/scripts/007_setup_acm.sh
   ```
1. **[Admin Host]** Verify ACM
   ```
   ${ABM_WORK_DIR}/scripts/008_verify_acm.sh
   ```
   **Verify the following**:
   - `Status` for each cluster shows `SYNCED` before proceeding.
     > **NOTE**: Errors may be displayed while the synchronization is in progress.

## Configure Anthos Service Mesh(ASM)

1. Connect to the administrative host
1. **[Admin Host]** Setup ASM
   ```
   ${ABM_WORK_DIR}/scripts/009_setup_asm.sh
   ```
1. **[Admin Host]** Verify ASM
   ```
   ${ABM_WORK_DIR}/scripts/010_verify_asm.sh
   ```
   **Verify the following**:
   - Deployments and Pods are READY.

1. **[Admin Host]** Create the ASM load balancer
   ```
   ${ABM_WORK_DIR}/scripts/gcp/lb-proxy/005_create_asm_lb.sh
   ```

## Deploy the example application

See the [Deploy the application](deploy-the-application.md) guide.

## Tear down

To delete all of the resources, the instances and projects can just be deleted. To rollback the environment, the Manual rollback steps can be applied until preferred state is reached.

### Delete projects

1. Open Cloud Shell
1. **[Cloud Shell]** Delete the cluster instances
   ```
   ${ABM_WORK_DIR}/scripts/gcp/995_delete_cluster_instances.sh
   ```
1. **[Cloud Shell]** Delete the administrative host
   ```
   ${ABM_WORK_DIR}/scripts/gcp/999_delete_admin_instance.sh
   ```
1. **[Cloud Shell]** Delete the GCP projects
   ```
   ${ABM_WORK_DIR}/scripts/999_delete_gcp_projects.sh
   ```

### Manual rollback

1. Connect to the administrative host
1. **[Admin Host]** Unregister the clusters
   ```
   ${ABM_WORK_DIR}/scripts/gcp/994_unregister_cluster.sh
   ```
1. **[Admin Host]** Delete the cluster instances
   ```
   ${ABM_WORK_DIR}/scripts/gcp/995_delete_cluster_instances.sh
   ```
1. **[Admin Host]** Delete the load balancers
   ```
   ${ABM_WORK_DIR}/scripts/gcp/lb-proxy/999_delete_lbs.sh
   ```
1. **[Admin Host]** Delete the cluster configurations
   ```
   ${ABM_WORK_DIR}/scripts/gcp/997_delete_cluster_configurations.sh
   ```
1. **[Admin Host]** Delete the Google service accounts
   ```
   ${ABM_WORK_DIR}/scripts/gcp/998_delete_gsas.sh
   ```
1. **[Admin Host]** Logout of the administrative host
   ```
   logout
   ```
1. **[Cloud Shell]** Delete the administrative host
   ```
   ${ABM_WORK_DIR}/scripts/gcp/999_delete_admin_instance.sh
   ```
1. **[Cloud Shell]** Delete the ACM Cloud Source Repository
   ```
   ${ABM_WORK_DIR}/scripts/998_delete_acm_csr.sh
   ```
1. **[Cloud Shell]** Delete the GCP projects
   ```
   ${ABM_WORK_DIR}/scripts/999_delete_gcp_projects.sh
   ```
