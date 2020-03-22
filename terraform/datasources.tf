data "aws_ami" "amzn_linux2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami*x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"]
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
data "aws_iam_policy_document" "endpoints_s3_policy" {
  statement {
    effect = "Allow"

    actions = ["s3:GetObject"]
    resources = [
      "arn:aws:s3:::aws-ssm-ap-southeast-2/*",
      "arn:aws:s3:::aws-windows-downloads-ap-southeast-2/*",
      "arn:aws:s3:::amazon-ssm-ap-southeast-2/*",
      "arn:aws:s3:::amazon-ssm-packages-ap-southeast-2/*",
      "arn:aws:s3:::ap-southeast-2-birdwatcher-prod/*",
      "arn:aws:s3:::patch-baseline-snapshot-ap-southeast-2/*"
    ]
  }
}
