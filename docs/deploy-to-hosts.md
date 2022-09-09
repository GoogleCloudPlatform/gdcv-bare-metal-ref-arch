# Deploy to self-managed hosts

## Google Cloud Platform(GCP) account requirements

See the [Logging into gcloud](https://cloud.google.com/anthos/gke/docs/bare-metal/1.6/installing/install-prereq#logging_into_gcloud) section of the [Installation prerequisities overview](https://cloud.google.com/anthos/gke/docs/bare-metal/1.6/installing/install-prereq) documentation for the IAM role requirements.

## Self-managed host requirements

This guide uses the `anthos` user for the deployment of the required software to the cluster hosts. It is best to setup the `anthos` user in a centralized authentication systems(LDAP, NIS, etc.) used by all of the hosts. If a centralized authentication system is not available, the `anthos` user can be provisioned manually. It is also possible to use another user by changing the ABMRA_DEPLOYMENT_USER environment variable.

**This guide assumes that the ABMRA_DEPLOYMENT_USER is already configured on all of the hosts(administrative and cluster)**

> **Note**: This guide uses Ubuntu 20.04 LTS as the OS for the administrative host.

## Prepare the administrative host

> **Note**: Do not use Cloud Shell as your administrative host. The administrative host should be a managed, standalone host. This host will contain configuration information and tools for the environment.

1. Connect to the administrative host
1. **[Admin Host]** Install `git`
   ```
   sudo apt-get update && sudo apt-get install -y git
   ```
1. **[Admin Host]** Clone this project to the administrative host
   ```
   git clone https://github.com/GoogleCloudPlatform/anthos-bare-metal-ref-arch.git
   ```
1. **[Admin Host]** Set the Organization ID or Folder ID where the projects will be created.
   > This step can be skipped if using existing projects.
   ```
   export ABMRA_ORGANIZATION_ID=
   ```
   **OR**
   ```
   export ABMRA_FOLDER_ID=
   ```
1. **[Admin Host]** Set the Billing Account ID of the Billing Account for the new projects.
   > This step can be skipped if using existing projects.
   ```
   export ABMRA_BILLING_ACCOUNT_ID=
   ```
1. **[Admin Host]** Set the Project IDs for the new or existing projects, if not set the following defaults will be used:
   ```
   export ABMRA_NETWORK_PROJECT_ID=project-0-net-prod
   export ABMRA_PLATFORM_PROJECT_ID=project-1-platform-prod
   export ABMRA_APP_PROJECT_ID=project-2-bofa-prod
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
1. **[Admin Host]** Generate the conf files
   ```
   ${ABMRA_WORK_DIR}/scripts/000_generate_conf_files.sh
   ```
1. **[Admin Host]** Prepare the administrative host
   ```
   ${ABMRA_WORK_DIR}//scripts/001_prepare_admin_host.sh
   ```
1. **[Admin Host]** Logout, the new shell configurations will take effect on next login.
   ```
   logout
   ```

## Create the GCP projects

1. Connect to the administrative host
1. **[Admin Host]** Authenticate `gcloud` and set the application-default
   ```
   gcloud auth login --activate --no-launch-browser --quiet --update-adc
   ```
1. **[Admin Host]** Create the GCP projects
   ```
   ${ABMRA_WORK_DIR}/scripts/002_create_gcp_projects.sh
   ```

## Create the Shared VPC

To create the Shared VPC in the ABMRA_NETWORK_PROJECT_ID project, the `Compute Shared VPC Admin` role is required for the organization or folder.

1. Connect to the administrative host
1. **[Admin Host]** Create the Shared VPC
   ```
   ${ABMRA_WORK_DIR}/scripts/003_create_shared_vpc.sh
   ```

## Prepare the cluster configuration files

1. Connect to the administrative host
1. **[Admin Host]** Prepare the cluster configuration files
   ```
   ${ABMRA_WORK_DIR}/scripts/004_prepare_configuration_files.sh
   ```

## Review the cluster configuration files

1. Connect to the administrative host
1. Review the cluster configuration files at the following locations:
   - **metal-1-apps-dc1a-prod**: `${ABMRA_BMCTL_WORKSPACE_DIR}/metal-1-apps-dc1a-prod/metal-1-apps-dc1a-prod.yaml`
   - **metal-2-apps-dc1b-prod**: `${ABMRA_BMCTL_WORKSPACE_DIR}/metal-2-apps-dc1b-prod/metal-2-apps-dc1b-prod.yaml`
   - **metal-3-apps-dc2a-prod**: `${ABMRA_BMCTL_WORKSPACE_DIR}/metal-3-apps-dc2a-prod/metal-3-apps-dc2a-prod.yaml`
   - **metal-4-apps-dc2b-prod**: `${ABMRA_BMCTL_WORKSPACE_DIR}/metal-4-apps-dc2b-prod/metal-4-apps-dc2b-prod.yaml`
1. Make any changes, such as IP addresses, to the configuration files before proceeding.

## Create the clusters

1. Connect to the administrative host
1. **[Admin Host]** Create the clusters
   ```
   ${ABMRA_WORK_DIR}/scripts/005_create_clusters.sh
   ```

## Configure Connect Gateway

1. Connect to the administrative host
1. **[Admin Host]** Configure Connect Gateway
   ```
   ${ABMRA_WORK_DIR}/scripts/006_configure_connect_gateway.sh
   ```
1. Open the URL provided by the script
1. Verify that all clusters show healthy

## Configure Anthos Config Management(ACM)

1. Connect to the administrative host
1. **[Admin Host]** Setup ACM
   ```
   ${ABMRA_WORK_DIR}/scripts/007_setup_acm.sh
   ```
1. **[Admin Host]** Verify ACM
   ```
   ${ABMRA_WORK_DIR}/scripts/008_verify_acm.sh
   ```
   **Verify the following**:
   - `Status` for each cluster shows `SYNCED` before proceeding.
     > **NOTE**: Errors may be displayed while the synchronization is in progress.

## Configure Anthos Service Mesh(ASM)

1. Connect to the administrative host
1. **[Admin Host]** Setup ASM
   ```
   ${ABMRA_WORK_DIR}/scripts/009_setup_asm.sh
   ```
1. **[Admin Host]** Verify ASM
   ```
   ${ABMRA_WORK_DIR}/scripts/010_verify_asm.sh
   ```
   **Verify the following**:
   - Deployments and Pods are READY.
   - Service is created and the `EXTERNAL-IP` is populated.

## Deploy the example application

See the [Deploy the application](deploy-the-application.md) guide.

## Tear down

1. Connect to the administrative host
1. **[Admin Host]** Reset the cluster hosts to the state prior to installation
   ```
   ${ABMRA_WORK_DIR}/scripts/997_reset_clusters.sh
   ```
1. **[Cloud Shell]** Delete the ACM Cloud Source Repository
   ```
   ${ABMRA_WORK_DIR}/scripts/998_delete_acm_csr.sh
   ```
1. **[Admin Host]** Delete the GCP projects
   ```
   ${ABMRA_WORK_DIR}/scripts/999_delete_gcp_projects.sh
   ```
