resource "aws_security_group" "openvpn" {
  name = "openvpn"
  description = "Allow OpenVPN access"
  vpc_id = "${aws_vpc.devops-demo.id}"
  # OpenVPN (tcp/443)
  ingress = {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # OpenVPN (udp/1194)
  ingress = {
    from_port = 1194
    to_port = 1194
    protocol = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "openvpn"
  }
}

resource "aws_security_group" "gocd-server" {
  name = "gocd-server"
  description = "Allow GO CD web UI"
  vpc_id = "${aws_vpc.devops-demo.id}"
  ingress {
    from_port = 8153
    to_port = 8153
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "gocd-server"
  }
}

resource "template_file" "ops-userdata" {
  template = "${file("ops-userdata.tpl")}"
  vars {
    hostname = "ops"
    domainname = "${aws_route53_zone.internal.name}"
    secrets_bucket = "${aws_s3_bucket.devops-demo-secrets.bucket}"
    aws_region = "${aws_s3_bucket.devops-demo-secrets.region}"
  }
}

resource "aws_instance" "ops" {
  instance_type = "t2.medium"
  ami = "${lookup(var.aws_amis, var.aws_region)}"
  iam_instance_profile = "${aws_iam_instance_profile.secrets_read_only.name}"
  subnet_id = "${aws_subnet.public.id}"
  private_ip = "10.0.0.101"
  associate_public_ip_address = true
  source_dest_check = true
  user_data = "${template_file.ops-userdata.rendered}"
  key_name = "devops-key"
  vpc_security_group_ids = [
    "${aws_security_group.public_egress.id}",
    "${aws_security_group.allow_ssh.id}",
    "${aws_security_group.openvpn.id}",
    "${aws_security_group.gocd-server.id}"
  ]
  tags {
    Name = "devops-demo-ops"
  }
}

# Add an A record to route-53
resource "aws_route53_record" "ops" {
  zone_id = "${aws_route53_zone.internal.id}"
  name = "ops"
  type = "A"
  ttl = "300"
  records = [
    "${aws_instance.ops.private_ip}"]
}

resource "template_file" "ops-in-addr-arpa-hostname" {
  template = "${file("in-addr-arpa-hostname.tpl")}"
  vars {
    ipv4 = "${aws_instance.ops.private_ip}"
  }
}

# Add inverse DNS record to route-53
resource "aws_route53_record" "ops-inverse" {
  zone_id = "${aws_route53_zone.reverse.id}"
  name = "${template_file.ops-in-addr-arpa-hostname.rendered}"
  type = "PTR"
  ttl = "300"
  records = [
    "ops.${aws_route53_zone.internal.name}."
  ]
}

resource "aws_route53_record" "ops_public" {
  count = "${replace(replace(replace(var.route53_public_hosted_zone_id, "/(?:none)|(.*)/", "$1"), "/^.+$/", "1"), "/$^/", "0")}"
  zone_id = "${var.route53_public_hosted_zone_id}"
  name = "ops"
  type = "CNAME"
  ttl = "60"
  records = [
    "${aws_instance.ops.public_dns}"
  ]
}