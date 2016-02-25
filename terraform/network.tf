resource "aws_vpc" "devops-demo" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags {
    Name = "devops_demo_vpc"
  }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = "${aws_vpc.devops-demo.id}"
  tags {
    Name = "devops_demo_gw"
  }
}

resource "aws_subnet" "public" {
  vpc_id = "${aws_vpc.devops-demo.id}"
  availability_zone = "${var.aws_region}a"
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = true
  tags {
    Name = "devops_demo_public"
    Role = "public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.devops-demo.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gateway.id}"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_security_group" "allow_ssh" {
  name = "allow_ssh"
  description = "Allow SSH connections from anywhere"
  vpc_id = "${aws_vpc.devops-demo.id}"
  ingress = {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "allow_ssh"
  }
}

resource "aws_security_group" "public_egress" {
  name = "public_egress"
  description = "allow outbound traffic to any host on the Internet"
  vpc_id = "${aws_vpc.devops-demo.id}"
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "public_egress"
  }
}

resource "aws_s3_bucket" "devops-demo-secrets" {
  bucket = "${format("devops-demo-secrets-%s", aws_vpc.devops-demo.id)}"
  acl = "private"
  force_destroy = true
  tags {
    Name = "devops-demo-secrets"
  }
}

resource "aws_iam_role" "secrets_read_only_role" {
  name = "secrets_read_only_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role" "secrets_read_write_role" {
  name = "secrets_read_write_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "secrets_s3_write_access_policy" {
  name = "secrets_s3_write_access"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "${aws_s3_bucket.devops-demo-secrets.arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy" "secrets_s3_read_access_policy" {
  name = "secrets_s3_read_access"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": [
        "${aws_s3_bucket.devops-demo-secrets.arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "${aws_s3_bucket.devops-demo-secrets.arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "secrets_s3_read_access_roles" {
  name = "secrets_s3_read_access_roles"
  roles = [
    "${aws_iam_role.secrets_read_only_role.name}",
    "${aws_iam_role.secrets_read_write_role.name}"
  ]
  policy_arn = "${aws_iam_policy.secrets_s3_read_access_policy.arn}"
}

resource "aws_iam_policy_attachment" "secrets_s3_write_access_roles" {
  name = "secrets_s3_write_access_roles"
  roles = [
    "${aws_iam_role.secrets_read_write_role.name}"
  ]
  policy_arn = "${aws_iam_policy.secrets_s3_write_access_policy.arn}"
}

resource "aws_iam_instance_profile" "secrets_read_only" {
  name = "secrets_read_only_instance_profile"
  depends_on = ["aws_iam_policy_attachment.secrets_s3_read_access_roles"]
  roles = [
    "${aws_iam_role.secrets_read_only_role.id}"
  ]
}


resource "aws_iam_instance_profile" "secrets_read_write" {
  name = "secrets_read_write_instance_profile"
  depends_on = ["aws_iam_policy_attachment.secrets_s3_read_access_roles", "aws_iam_policy_attachment.secrets_s3_write_access_roles"]
  roles = [
    "${aws_iam_role.secrets_read_write_role.id}"
  ]
}


