## RKE2 FRX

This is a simple rke2 in aws terraform setup.
Might be broken, might be terrible, might be great,
... it is a work in progress.

Requirements - 
  * existing VPC & Subnets
  * existing AWS Credentials, Access/Secret Keys
  * Rancher Install with Credentials, API Token
  * latest versions of Rancher, terraform, & rancher2 tf provider

Config options for aws region, names, and machine_global_config are opinionated, open for choice of preference.

If it complains about the cloud-credential, issue ``` terraform refresh && terraform apply ``` again and all should be well.

