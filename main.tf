data "template_file" "mongo_config" {
  template = "${file("${path.module}/mongod.conf.tpl")}"

  vars {
    project      = "${var.project}"
    zone         = "${var.zone}"
  }
}

resource "google_compute_image" "mongodb-image" {
  name = "mongodb-image"

  raw_disk {
    source = "${var.raw_image_source}"
  }
  timeouts {
    create = "10m"
  }

}

resource "google_compute_instance" "mongo_instance" {
  name         = "${var.instance_name}-${count.index}"
  machine_type = "n1-standard-1"
  zone         = "${var.zone}"
  count        = "${var.node_count}"

  tags = ["mongo", "mongodb"]


  boot_disk {
    initialize_params {
      image = "${google_compute_image.mongodb-image.self_link}"
      type = "pd-ssd"
      size = "30"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  metadata {
    foo = "bar"
    ssh-keys = "devops:${tls_private_key.provision_key.public_key_openssh}"
  }

  //metadata_startup_script = "systemctl enable mongodb.service;"

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-rw","monitoring-write","logging-write","https://www.googleapis.com/auth/trace.append"]
  }

  provisioner "file" {
    content     = "${data.template_file.mongo_config.rendered}"
    destination = "/tmp/mongod.conf"

    connection {
      type        = "ssh"
      user        = "devops"
      private_key = "${tls_private_key.provision_key.private_key_pem}"
      agent       = false
    }
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "devops"
      private_key = "${tls_private_key.provision_key.private_key_pem}"
      agent       = false
    }

    inline = [
      "sudo mv /tmp/mongod.conf /etc",
      "sudo systemctl start mongod.service"
    ]
  }
  //not sure if ok for production
  allow_stopping_for_update = false
 }

 resource "tls_private_key" "provision_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "google_compute_firewall" "mongodb-allow-cluster" {
  name    = "mongodb-allow-cluster-${var.instance_name}"
  network = "default"
  priority = "1000"

  allow {
    protocol = "tcp"
    ports    = ["27017"]
  }
  source_ranges = ["${var.cluster_ipv4_cidr}"]
  source_tags = ["mongodb"]
}