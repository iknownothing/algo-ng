resource "tls_private_key" "client" {
  count       = length(var.vpn_users)
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_cert_request" "client" {
  count           = length(var.vpn_users)
  key_algorithm   = "ECDSA"
  private_key_pem = tls_private_key.client.*.private_key_pem[count.index]
  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibilty in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  dns_names = [var.vpn_users[count.index]]

  subject {
    common_name = var.vpn_users[count.index]
  }
}

resource "tls_locally_signed_cert" "client" {
  count                 = length(var.vpn_users)
  # depends_on            = [null_resource.user_crl]
  cert_request_pem      = tls_cert_request.client.*.cert_request_pem[count.index]
  ca_key_algorithm      = "ECDSA"
  ca_private_key_pem    = tls_private_key.ca.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.ca.cert_pem
  validity_period_hours = 87600

  allowed_uses = [
    "client_auth",
    "server_auth",
    "key_encipherment",
    "digital_signature",
  ]
}

resource "local_file" "user_private_keys" {
  count    = length(var.vpn_users)
  content  = tls_private_key.client.*.private_key_pem[count.index]
  filename = "${var.algo_config}/ipsec/manual/${var.vpn_users[count.index]}.key.pem"

  provisioner "local-exec" {
    command = "chmod 0600 ${var.algo_config}/ipsec/manual/${var.vpn_users[count.index]}.key.pem"
  }
}

resource "local_file" "user_certs" {
  # depends_on = [null_resource.user_crl]
  count      = length(var.vpn_users)
  content    = tls_locally_signed_cert.client.*.cert_pem[count.index]
  filename   = "${var.algo_config}/ipsec/manual/${var.vpn_users[count.index]}.crt.pem"

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-ec"]
    working_dir = "${var.algo_config}/ipsec/manual/"

    command = <<-EOF
      chmod 0600 ${var.vpn_users[count.index]}.crt.pem
      mkdir .for_crl/ || true
      cp -f ${var.vpn_users[count.index]}.crt.pem \
        .for_crl/${var.vpn_users[count.index]}.crt.pem
EOF

  }
}

resource "local_file" "user_ssh_private_keys" {
  count = var.components["ssh_tunneling"] == 0 ? 0 : length(var.vpn_users)
  content = tls_private_key.client.*.private_key_pem[count.index]
  filename = "${var.algo_config}/${var.vpn_users[count.index]}.ssh.pem"

  provisioner "local-exec" {
    command = "chmod 0600 ${var.algo_config}/${var.vpn_users[count.index]}.ssh.pem"
  }
}

resource "random_id" "client_p12_pass" {
  byte_length = 8
}

resource "null_resource" "client_p12" {
  count = length(var.vpn_users)

  triggers = {
    vpn_users = join(",", var.vpn_users)
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-ec"]
    working_dir = "${var.algo_config}/ipsec/manual/"

    command = <<-EOF
              umask 077;
              openssl pkcs12 \
                -in <(echo "$CERT") \
                -inkey <(echo "$KEY") \
                -export \
                -name ${var.vpn_users[count.index]} \
                -out ${var.vpn_users[count.index]}.p12 \
                -passout pass:"${random_id.client_p12_pass.hex}"
              EOF


    environment = {
      CERT = tls_locally_signed_cert.client.*.cert_pem[count.index]
      KEY  = tls_private_key.client.*.private_key_pem[count.index]
    }
  }
}

# data "local_file" "client_p12" {
#   depends_on = [null_resource.client_p12]
#   count      = length(var.vpn_users)
#   filename   = "${var.algo_config}/ipsec/manual/${var.vpn_users[count.index]}.p12"
# }
#
# resource "local_file" "client_p12_base64" {
#   count    = length(var.vpn_users)
#   content  = base64encode(data.local_file.client_p12.*.content[count.index])
#   filename = "${var.algo_config}/ipsec/manual/${var.vpn_users[count.index]}.p12.base64"
#
#   provisioner "local-exec" {
#     command = "chmod 0600 ${var.algo_config}/ipsec/manual/${var.vpn_users[count.index]}.p12.base64"
#   }
#
#   # lifecycle {
#   #   ignore_changes = [content]
#   # }
# }

# resource "null_resource" "user_crl" {
#   triggers = {
#     vpn_users = join(",", var.vpn_users)
#   }
#
#   provisioner "local-exec" {
#   interpreter = ["/bin/bash", "-ec"]
#   working_dir = "${var.algo_config}/ipsec/manual/"
#   command     = "${path.module}/files/make_crl.sh"
#
#   environment = {
#     USERS      = join(",", var.vpn_users)
#     KEY        = tls_private_key.ca.private_key_pem
#     CERT       = tls_self_signed_cert.ca.cert_pem
#     OPENSSLCNF = file("${path.module}/files/openssl.cnf")
#   }
#   }
# }
#
# data "local_file" "user_crl" {
#   depends_on = [null_resource.user_crl]
#   filename   = "${var.algo_config}/ipsec/manual/crl.pem"
# }
