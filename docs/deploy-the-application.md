# Deploy the application

The Bank of Anthos source code can be found at https://github.com/GoogleCloudPlatform/bank-of-anthos.

## Clone the Bank of Anthos repository

1. Connect to the administrative host
1. **[Admin Host]** Clone the application repository
   ```
   ${ABM_WORK_DIR}/scripts/012_clone_application_repository.sh
   ```

## Deploy the application

1. Connect to the administrative host
1. **[Admin Host]** Deploy the application
   ```
   ${ABM_WORK_DIR}/scripts/013_deploy_application.sh
   ```
1. **[Admin Host]** Verify the application
   ```
   ${ABM_WORK_DIR}/scripts/014_verify_application.sh
   ```

## Configure the application to use ASM

1. Connect to the administrative host
1. **[Admin Host]** Configure the application
   ```
   ${ABM_WORK_DIR}/scripts/015_configure_application_asm.sh
   ```
1. **[Admin Host]** Verify the configuration
   ```
   ${ABM_WORK_DIR}/scripts/016_verify_application_asm.sh
   ```
