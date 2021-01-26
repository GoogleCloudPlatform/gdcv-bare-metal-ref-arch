# Anthos Reference Architecture - Anthos on bare metal

## IP address allocation

The default IP address allocations are as follows. If these allocations need to be modify they can changed in the cluster configuration files specified in the [Review the cluster configuration files](docs/deploy-to-hosts.md#review-the-cluster-configuration-files) section.

| Cluster               | Hosts         | Pods           | Services     | Load Balancers         |
| --------------------- | ------------- | -------------- | ------------ | ---------------------- |
| metal-1-app-dc1a-prod | 10.185.1.0/24 | 192.168.0.0/16 | 10.96.0.0/12 | 10.185.1.3-10.185.1.10 |
| metal-2-app-dc1b-prod | 10.185.2.0/24 | 192.168.0.0/16 | 10.96.0.0/12 | 10.185.2.3-10.185.2.10 |
| metal-3-app-dc2a-prod | 10.195.1.0/24 | 192.168.0.0/16 | 10.96.0.0/12 | 10.195.1.3-10.195.1.10 |
| metal-4-app-dc2b-prod | 10.195.2.0/24 | 192.168.0.0/16 | 10.96.0.0/12 | 10.195.2.3-10.195.2.10 |

**metal-1-app-dc1a-prod**

```
# Hosts
10.185.1.11    metal-1-prod-cp-1
10.185.1.12    metal-1-prod-cp-2
10.185.1.13    metal-1-prod-cp-3
10.185.1.21    metal-1-prod-worker-1
10.185.1.22    metal-1-prod-worker-2
10.185.1.23    metal-1-prod-worker-3

# VIPs
10.185.1.2     metal-1-prod-cp
10.185.1.3     metal-1-prod-ingress
```

**metal-2-app-dc1b-prod**

```
# Hosts
10.185.2.11    metal-2-prod-cp-1
10.185.2.12    metal-2-prod-cp-2
10.185.2.13    metal-2-prod-cp-3
10.185.2.21    metal-2-prod-worker-1
10.185.2.22    metal-2-prod-worker-2
10.185.2.23    metal-2-prod-worker-3

# VIPs
10.185.2.2     metal-2-prod-cp
10.185.2.3     metal-2-prod-ingress
```

**metal-3-app-dc2a-prod**

```
# Hosts
10.195.1.11    metal-3-prod-cp-1
10.195.1.12    metal-3-prod-cp-2
10.195.1.13    metal-3-prod-cp-3
10.195.1.21    metal-3-prod-worker-1
10.195.1.22    metal-3-prod-worker-2
10.195.1.23    metal-3-prod-worker-3

# VIPs
10.195.1.2     metal-3-prod-cp
10.195.1.3     metal-3-prod-ingress
```

**metal-4-app-dc2b-prod**

```
# Hosts
10.195.2.11    metal-4-prod-cp-1
10.195.2.12    metal-4-prod-cp-2
10.195.2.13    metal-4-prod-cp-3
10.195.2.21    metal-4-prod-worker-1
10.195.2.22    metal-4-prod-worker-2
10.195.2.23    metal-4-prod-worker-3

# VIPs
10.195.2.2     metal-4-prod-cp
10.195.2.3     metal-4-prod-ingress
```

## Deploy the platform

This guide can be used to deploy Anthos on bare metal for two different scenarios:

**[Deploy to self-managed hosts](docs/deploy-to-hosts.md)**  
This scenario walks through the deployment of Anthos on bare metal using self-managed hosts. A self-managed host is a host that meets the requirements and prerequisites for Anthos on bare metal, regardless of the underlying infrastructure. There is no infrastructure automation provided for the hosts in this scenario as it relies on the hosts being preconfigured for the Anthos on bare metal installation.

**[Deploy to GCE instances with VXLAN](docs/deploy-to-gce-instances-vxlan.md)**

> This scenario is for demonstration purposes only and should NOT be used for production workloads.

This scenario walks through the deployment of Anthos on bare metal using GCE instances with VXLAN and GCP resources. There is infrastructure automation to create the required resources on GCP.

## Deploy the application

Once the platform is deploy the Bank of Anthos application can be deployed using the [Deploy the application](docs/deploy-the-application.md) guide
