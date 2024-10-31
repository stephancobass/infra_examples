resource "tls_private_key" "privat_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair_custom" {
  key_name   = var.aws_key_name
  public_key = tls_private_key.privat_key.public_key_openssh

  provisioner "local-exec" { 
    command = "echo '${tls_private_key.privat_key.private_key_pem}' > ./app_instance.pem"
  }
}