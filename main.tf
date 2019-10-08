data "template_file" "mongo_config" {
  template = "${var.rs == "none" ? file("${path.module}/mongod.conf.tpl") : file("${path.module}/mongod.rs.conf.tpl")}"

  vars {
    project      = "${var.project}"
    zone         = "${var.zone}"
    rs           = "${var.rs}"
  }
}

resource "google_compute_image" "mongodb-image" {
  name = "${var.instance_name}-mongodb-image"

  raw_disk {
    source = "${var.raw_image_source}"
  }
  timeouts {
    create = "10m"
  }

}

resource "tls_private_key" "mongo_key" {
  algorithm = "RSA"
  rsa_bits  = 756
}

resource "google_compute_disk" "mongo_data_disk" {
  name  = "${var.instance_name}-${count.index}-persistent-data"
  type  = "${var.data_disk_type}"
  size  = "${var.data_disk_gb}"
  zone  = "${var.zone}"
  count = "${var.instance_count}"
}

resource "google_compute_instance" "mongo_instance" {
  name         = "${var.instance_name}-${count.index}"
  machine_type = "${var.machine_type}"
  zone         = "${var.zone}"
  count        = "${var.instance_count}"

  tags = ["mongo", "mongodb"]


  boot_disk {
    initialize_params {
      image = "${google_compute_image.mongodb-image.self_link}"
      type = "pd-standard"
      size = "10"
    }
  }
  attached_disk {
    source = "${var.instance_name}-${count.index}-persistent-data"
    device_name = "mongopd"
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

  provisioner "file" {
    content      = "${base64encode(tls_private_key.mongo_key.private_key_pem)}"
    destination = "/tmp/mongodb.key"

    connection {
      type        = "ssh"
      user        = "devops"
      private_key = "${tls_private_key.provision_key.private_key_pem}"
      agent       = false
    }
  }

  provisioner "file" {
    source      = "${path.module}/bootstrap.sh"
    destination = "/tmp/bootstrap.sh"

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
      "chmod +x /tmp/bootstrap.sh",
      "/tmp/bootstrap.sh > /tmp/bootstrap",
    ]
  }
  //not sure if ok for production
  allow_stopping_for_update = false

  depends_on = ["google_compute_disk.mongo_data_disk"]
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
