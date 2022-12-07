### tfvars.tf or environment.tf

variable "api_url" {
  description = "rancher api url"
  default     = "https://$RANCHER-URL/v3"
}

variable "token_key" {
  description = "api key to use for tf"
  default     = "$USERID:$TOKEN"
}

### providers.tf

provider "rancher2" {
  api_url   = var.api_url
  token_key = var.token_key
  ###insecure  = true
}

### versions.tf, latest versions

terraform {
  required_providers {
    rancher2 = {
      source  = "rancher/rancher2"
      version = ">= 1.25.0"
    }
  }
  required_version = ">= 1.3.6"
}

### add rancher-labs cloud-credential for aws ca-central-1

resource "rancher2_cloud_credential" "rancher-labs" {
  name = "rancher-labs"
  amazonec2_credential_config {
    access_key = "$ACCESSKEY"
    secret_key = "$SECRETKEY"
  }
}

### end of provider, environment & authentication


# Create amazonec2 machine config v2
resource "rancher2_machine_config_v2" "ec2-frx" {
  generate_name = "ec2-frx"
  amazonec2_config {
    ami            = "ami-0859074604ca21d57" ### ubuntu 20.04 latest
    region         = "ca-central-1"
    instance_type  = "t3a.large"
    security_group = ["rancher-nodes"]
    subnet_id      = "$EXISTINGSUBNET"
    vpc_id         = "$EXISTINGVPCID"
    zone           = "$ZONELETTER"
    ###security_group_readonly = "true"
  }
}

# Create a new rancher v2 amazonec2 RKE2 Cluster v2
resource "rancher2_cluster_v2" "ec2-frx" {
  name                                     = "ec2-frx"
  kubernetes_version                       = "v1.23.14+rke2r1"
  fleet_namespace                          = "fleet-default"
  enable_network_policy                    = false
  default_cluster_role_for_project_members = "user"
  depends_on = [
    rancher2_cloud_credential.rancher-labs
  ]
  rke_config {
    machine_pools {
      name                         = "pool001"
      cloud_credential_secret_name = rancher2_cloud_credential.rancher-labs.id
      control_plane_role           = true
      etcd_role                    = true
      worker_role                  = true
      quantity                     = 3
      machine_config {
        kind = rancher2_machine_config_v2.ec2-frx.kind
        name = rancher2_machine_config_v2.ec2-frx.name
      }
    }
    machine_global_config = <<EOF
---
write-kubeconfig-mode: "0644"
tls-san:
  - "*.kubefred.com"
kube-proxy-arg:
  - "proxy-mode=ipvs"
kubelet-arg:                        
  - "log-flush-frequency=10s"       
  - "container-log-max-files=4"     
  - "container-log-max-size=400Mi"  
cni: cilium
disable-cloud-controller: true
EOF
  }
}

### end of main.tf
