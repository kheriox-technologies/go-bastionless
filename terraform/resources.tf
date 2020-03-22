# -----------------------------------------------------------------------------------
# Key Pairs
# -----------------------------------------------------------------------------------
resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_key_pair" "key_pair" {
  key_name   = "${var.app_name}-key"
  public_key = tls_private_key.private_key.public_key_openssh
}

# -----------------------------------------------------------------------------------
# Store keys in SSM Parameter Store
# -----------------------------------------------------------------------------------
resource "aws_ssm_parameter" "private_key_ssm_param" {
  name        = "/${var.app_name}/private-key"
  description = "Private Key"
  type        = "SecureString"
  value       = tls_private_key.private_key.private_key_pem
}
resource "aws_ssm_parameter" "public_key_ssm_param" {
  name        = "/${var.app_name}/public-key"
  description = "Public Key"
  type        = "SecureString"
  value       = tls_private_key.private_key.public_key_pem
}
resource "aws_ssm_parameter" "public_key_openssh_ssm_param" {
  name        = "/${var.app_name}/public-key-openssh"
  description = "Public Key in openssh format"
  type        = "SecureString"
  value       = tls_private_key.private_key.public_key_openssh
}

# -----------------------------------------------------------------------------------
# Security Groups
# -----------------------------------------------------------------------------------
resource "aws_security_group" "bastion_sg" {
  name        = "${var.app_name}-bastion-sg"
  description = "Security Group for Bastion EC2 instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "private_sg" {
  name        = "${var.app_name}-private-sg"
  description = "Security Group for Private EC2 instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "endpoint_sg" {
  name        = "${var.app_name}-endpoint-sg"
  description = "Security Group for VPC Endpoints"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -----------------------------------------------------------------------------------
# IAM Resources
# -----------------------------------------------------------------------------------
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.app_name}-ec2-role"
  path = "/"
  role = aws_iam_role.ec2_role.name
}
resource "aws_iam_role" "ec2_role" {
  name               = "${var.app_name}-ec2-role"
  path               = "/"
  description        = "Role assigned to EC2 Instance"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}
resource "aws_iam_role_policy_attachment" "managed_policies" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = var.managed_policies[count.index]
  count      = length(var.managed_policies)
}
resource "aws_iam_policy" "endpoints_s3_policy" {
  name   = "endpoints-s3-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.endpoints_s3_policy.json
}
resource "aws_iam_role_policy_attachment" "endpoints_s3_policy-attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.endpoints_s3_policy.arn
}

# -----------------------------------------------------------------------------------
# VPC Endpoints
# -----------------------------------------------------------------------------------
resource "aws_vpc_endpoint" "endpoints" {
  count             = length(var.vpc_endpoints)
  vpc_id            = var.vpc_id
  service_name      = var.vpc_endpoints[count.index]
  vpc_endpoint_type = "Interface"
  private_dns_enabled = "true"
  security_group_ids = [
    aws_security_group.endpoint_sg.id
  ]
  subnet_ids = [var.private_subnet]
}

# -----------------------------------------------------------------------------------
# EC2 Instances
# -----------------------------------------------------------------------------------
resource "aws_instance" "bastion_instance" {
  ami                    = data.aws_ami.amzn_linux2.id
  key_name               = aws_key_pair.key_pair.key_name
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  subnet_id              = var.public_subnet
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
  root_block_device {
    delete_on_termination = "true"
    encrypted             = "true"
    volume_size           = var.root_block_device.size
    volume_type           = var.root_block_device.type
  }
  user_data                   = file("scripts/user-data.sh")
  associate_public_ip_address = "true"

  tags = {
    Name = "${var.app_name}-bastion"
  }
}
resource "aws_instance" "private_instance" {
  ami                    = data.aws_ami.amzn_linux2.id
  key_name               = aws_key_pair.key_pair.key_name
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  subnet_id              = var.private_subnet
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
  root_block_device {
    delete_on_termination = "true"
    encrypted             = "true"
    volume_size           = var.root_block_device.size
    volume_type           = var.root_block_device.type
  }
  user_data = file("scripts/user-data.sh")

  tags = {
    Name = "${var.app_name}-private"
  }
}
