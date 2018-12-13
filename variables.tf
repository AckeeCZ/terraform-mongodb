variable "project" {}
variable "zone" {}
variable "instance_name" {}
variable "cluster_ipv4_cidr" {}

variable "node_count" {
  default = "1"
}
variable "raw_image_source" {}