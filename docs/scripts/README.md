# GKE Enterprise reference architecture: Google Distributed Cloud Virtual(GDCV) for Bare Metal

**The script version of this repository has been deprecated in favor of the Terraform version, see the main [README](/README.md)**

## Deploy the platform

This guide can be used to deploy [GDCV for Bare Metal](https://cloud.google.com/anthos/clusters/docs/bare-metal/latest/concepts/about-bare-metal) in various scenarios:

**[Deploy to self-managed hosts](/docs/scripts/deploy-to-hosts.md)**

This scenario walks through the deployment of GDCV for Bare Metal using self-managed hosts. A self-managed host is a physical or virutal machine that meets the [requirements](https://cloud.google.com/anthos/clusters/docs/bare-metal/latest/installing/node-machine-prerequisites#resource_requirements_for_all_cluster_types_using_the_default_profile) and [prerequisites](https://cloud.google.com/anthos/clusters/docs/bare-metal/latest/installing/install-prereq) for GDCV for Bare Metal. There is no infrastructure automation provided for the hosts in this scenario as it relies on the hosts being preconfigured for the GDCV for Bare Metal installation.

|                    |               |
| ------------------ | ------------- |
| Deployment Model   | Hybrid        |
| Load Balancer Mode | Bundled       |
| Infrastructure     | User Provided |


### Demonstration Purposes Only

The following scenario are for demonstration purposes only and should NOT be used for production workloads.

**[Deploy to GCE instances using VXLAN](/docs/scripts/deploy-to-gce-instances-vxlan.md)**

This scenario walks through the deployment of Anthos on bare metal using GCE instances with VXLAN and GCP resources. There is infrastructure automation to create the required resources on GCP.

|                    |         |
| ------------------ | ------- |
| Deployment Model   | Hybrid  |
| Load Balancer Mode | Bundled |
| Infrastructure     | GCP     |

**[Deploy to GCE instances using GCLBs](/docs/scripts/deploy-to-gce-instances-lb-proxy.md)**

This scenario walks through the deployment of Anthos on bare metal using GCE instances with Google Cloud Load Balancers(GCLBs) and GCP resources. There is infrastructure automation to create the required resources on GCP.

|                    |        |
| ------------------ | ------ |
| Deployment Model   | Hybrid |
| Load Balancer Mode | Manual |
| Infrastructure     | GCP    |

**[Deploy to GCE instances with GPUs using GCLBs](/docs/scripts/deploy-to-gce-instances-lb-proxy-gpu.md)**

This scenario walks through the deployment of Anthos on bare metal using GPU enabled GCE instances with Google Cloud Load Balancers(GCLBs) and GCP resources. There is infrastructure automation to create the required resources on GCP.

|                    |        |
| ------------------ | ------ |
| Deployment Model   | Hybrid |
| Load Balancer Mode | Manual |
| Infrastructure     | GCP    |

## Deploy the application

Once the platform is deploy the Bank of Anthos application can be deployed using the [Deploy the application](/docs/scripts/deploy-the-application-boa.md) guide.
