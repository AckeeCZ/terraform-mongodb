# Ackee GCE Mongodb Terraform module

This module is primary written for provisioning of GCE instance from our Mongodb image (https://github.com/AckeeDevOps/packer-mongodb)

It does a few things :
* Downloads RAW disk from GCS and create an image from it. (you can generate your own image with Packer using https://github.com/AckeeDevOps/packer-mongodb)
* Create SSH key for instance provisioning
* Provision MongoDB config on GCE instance
* Create (GCP) firewall rules so GKE pods can reach GCE MongoDB instances


## Configuration

https://github.com/AckeeDevOps/terraform-mongodb/blob/master/variables.tf explanation  (followed by default values if applicable) :

* project - name of GCP project
* zone - zone of GCP project
* instance_name - base for GCE instances name
* cluster_ipv4_cidr - IPv4 CIDR of GKE cluster - for firewall rule setting
* node_count:1 - number of MongoDB nodes to deploy
* raw_image_source -  URL of tar archive containing RAW source for MongoDB image
