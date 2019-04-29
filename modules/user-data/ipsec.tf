data "template_file" "ipsec" {
  template = file("${path.module}/files/ipsec.conf")

  vars = {
    ike                  = var.components["windows"] == 1 ? var.ciphers_compat["ike"] : var.ciphers["ike"]
    esp                  = var.components["windows"] == 1 ? var.ciphers_compat["esp"] : var.ciphers["esp"]
    strongswan_log_level = var.strongswan_log_level
    rightsourceip        = "${var.ipsec_network["ipv4"]}${var.ipv6 == 0 ? "" : ",${var.ipsec_network["ipv6"]}"}"
    rightdns             = var.components["dns_encryption"] == 1 || var.components["dns_adblocking"] == 1 ? var.local_service_ip : "${join(",", var.ipv4_dns_servers)}${var.ipv6 == 0 ? "" : ",${join(",", var.ipv6_dns_servers)}"}"
  }
}

data "template_file" "strongswan" {
  template = file("${path.module}/cloud-init/010-strongswan.yml")

  vars = {
    strongswan = jsonencode(file("${path.module}/files/strongswan.conf"))
    ipsec      = jsonencode(data.template_file.ipsec.rendered)
  }
}
