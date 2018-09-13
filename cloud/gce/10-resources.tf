module "ssh-key" {
  source            = "../../modules/ssh-key/"
  unmanaged         = "${var.unmanaged}"
  algo_config       = "${local.algo_config}"
  ssh_key_algorithm = "RSA"
}

module "tls" {
  source            = "../../modules/tls/"
  server_address    = "${module.cloud-gce.server_address}"
  vpn_users         = "${var.vpn_users}"
  algo_config       = "${local.algo_config}"
}

module "user-data" {
  source                      = "../../modules/user-data/"
  vpn_users                   = "${var.vpn_users}"
  clients_public_key_openssh  = "${module.tls.clients_public_key_openssh}"
  components                  = "${var.components}"
  ipv6                        = true
  base64_encode               = false
  gzip                        = false
}

module "cloud-gce" {
  source              = "../../modules/cloud-gce/"
  image               = "${var.image["gce"]}"
  size                = "${var.size["gce"]}"
  region              = "${var.region}"
  public_key_openssh  = "${module.ssh-key.public_key_openssh}"
  user_data           = "${module.user-data.template_cloudinit_config}"
  algo_name           = "${var.algo_name}"
}
