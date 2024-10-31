resource "tls_private_key" "privat_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_security_group" "app_sg" {
  name        = "app_sg"
  description = "Allow ports for app"
  vpc_id      = local.vpc_id
}

resource "aws_security_group_rule" "ssh_ingress" {
  security_group_id = aws_security_group.app_sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "all_egress" {
  security_group_id = aws_security_group.app_sg.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "backend_ingress_http" {
  security_group_id = "${aws_security_group.app_sg.id}"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "backend_ingress_https" {
  security_group_id = "${aws_security_group.app_sg.id}"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "db_ingress" {
  security_group_id = "${aws_security_group.app_sg.id}"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22421
  to_port           = 22421
  cidr_blocks       = var.db_access_ips
}


data "aws_ami" "latest_ami_al2023" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}


resource "aws_instance" "app_app" {
  ami                     = data.aws_ami.latest_ami_al2023.id
  instance_type           = var.instance_type
  key_name                = local.key_pair_custom_name
  vpc_security_group_ids  = [aws_security_group.app_sg.id]
  subnet_id               = local.public_subnet_id
  iam_instance_profile    = aws_iam_instance_profile.app_instance_profile.name
  user_data               = file("userdata.sh")

  root_block_device {
    delete_on_termination = false
    volume_size = 10
    volume_type = "gp3"
  }

  ebs_optimized           = true
  tags = {
    Name = "app_app"
  }

}

resource "aws_eip" "app_app" {
  instance = aws_instance.app_app.id
  domain   = "vpc"

  tags = {
    Name = "app_app"
  }

}