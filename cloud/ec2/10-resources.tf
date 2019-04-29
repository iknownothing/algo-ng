module "ssh-key" {
  source            = "../../modules/ssh-key/"
  algo_config       = module.post-cloud.algo_config
  ssh_key_algorithm = "RSA"
}

module "tls" {
  source         = "../../modules/tls/"
  algo_config    = module.post-cloud.algo_config
  vpn_users      = var.vpn_users
  components     = var.components
  server_address = module.cloud-ec2.server_address
}

module "user-data" {
  source                     = "../../modules/user-data/"
  base64_encode              = true
  gzip                       = true
  vpn_users                  = var.vpn_users
  components                 = var.components
  unmanaged                  = var.unmanaged
  max_mss                    = var.max_mss
  system_upgrade             = var.system_upgrade
  clients_public_key_openssh = module.tls.clients_public_key_openssh
  ipv6                       = module.cloud-ec2.ipv6
}

module "cloud-ec2" {
  source             = "../../modules/cloud-ec2/"
  region             = var.region
  algo_name          = var.algo_name
  public_key_openssh = module.ssh-key.public_key_openssh
  user_data          = module.user-data.template_cloudinit_config
  wireguard_network  = module.user-data.wireguard_network
}

module "configs" {
  source            = "../../modules/configs/"
  algo_config       = module.post-cloud.algo_config
  vpn_users         = var.vpn_users
  components        = var.components
  ipv6              = module.cloud-ec2.ipv6
  server_address    = module.cloud-ec2.server_address
  client_p12_pass   = module.tls.client_p12_pass
  ca_cert           = module.tls.ca_cert
  server_cert       = module.tls.server_cert
  server_key        = module.tls.server_key
  crl               = module.tls.crl
  ssh_user          = module.cloud-ec2.ssh_user
  private_key       = module.ssh-key.private_key_pem
  server_id         = module.cloud-ec2.server_id
  wg_users_private  = module.user-data.wg_users_private
  wg_users_public   = module.user-data.wg_users_public
  local_service_ip  = module.user-data.local_service_ip
  wireguard_network = module.user-data.wireguard_network
  ondemand          = var.ondemand
}

module "post-cloud" {
  source         = "../../modules/post-cloud/"
  server_address = module.cloud-ec2.server_address
}
