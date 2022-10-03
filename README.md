# Anthos Reference Architecture - Anthos on bare metal

This repository includes the scripts and documentation to deploy the architecture described in [Anthos reference architecture: Anthos on bare metal](https://cloud.google.com/architecture/ara-anthos-on-bare-metal).

## Deploy the platform

This guide can be used to deploy Anthos on bare metal in various scenarios:

**[Deploy to self-managed hosts](docs/deploy-to-hosts.md)**

This scenario walks through the deployment of Anthos on bare metal using self-managed hosts. A self-managed host is a host that meets the requirements and prerequisites for Anthos on bare metal, regardless of the underlying infrastructure. There is no infrastructure automation provided for the hosts in this scenario as it relies on the hosts being preconfigured for the Anthos on bare metal installation.

|                    |               |
| ------------------ | ------------- |
| Deployment Model   | Hybrid        |
| Load Balancer Mode | Bundled       |
| Infrastructure     | User Provided |


### Demonstration Purposes Only

The following scenario are for demonstration purposes only and should NOT be used for production workloads.

**[Deploy to GCE instances using VXLAN](docs/deploy-to-gce-instances-vxlan.md)**

This scenario walks through the deployment of Anthos on bare metal using GCE instances with VXLAN and GCP resources. There is infrastructure automation to create the required resources on GCP.

|                    |         |
| ------------------ | ------- |
| Deployment Model   | Hybrid  |
| Load Balancer Mode | Bundled |
| Infrastructure     | GCP     |

**[Deploy to GCE instances using GCLBs](docs/deploy-to-gce-instances-lb-proxy.md)**

This scenario walks through the deployment of Anthos on bare metal using GCE instances with Google Cloud Load Balancers(GCLBs) and GCP resources. There is infrastructure automation to create the required resources on GCP.

|                    |        |
| ------------------ | ------ |
| Deployment Model   | Hybrid |
| Load Balancer Mode | Manual |
| Infrastructure     | GCP    |

**[Deploy to GCE instances with GPUs using GCLBs](docs/deploy-to-gce-instances-lb-proxy-gpu.md)**

This scenario walks through the deployment of Anthos on bare metal using GPU enabled GCE instances with Google Cloud Load Balancers(GCLBs) and GCP resources. There is infrastructure automation to create the required resources on GCP.

|                    |        |
| ------------------ | ------ |
| Deployment Model   | Hybrid |
| Load Balancer Mode | Manual |
| Infrastructure     | GCP    |

## Deploy the application

Once the platform is deploy the Bank of Anthos application can be deployed using the [Deploy the application](docs/deploy-the-application-boa.md) guide.
