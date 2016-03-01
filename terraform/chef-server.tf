resource "aws_security_group" "chef_server" {
  name = "chef_server"
  description = "Allow ingress for chef-server ports"
  vpc_id = "${aws_vpc.devops-demo.id}"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "template_file" "chef-server-userdata" {
  template = "${file("chef-server-userdata.tpl")}"
  vars {
    hostname = "chef-server"
    domainname = "${aws_route53_zone.internal.name}"
    chef_admin_user_name = "${var.chef_server_admin_user_name}"
    chef_admin_user_full_name = "${var.chef_server_admin_user_full_name}"
    chef_admin_user_email = "${var.chef_server_admin_user_email}"
    chef_admin_user_password = "${var.chef_server_admin_user_password}"
    chef_deploy_user_name = "${var.chef_server_deploy_user_name}"
    chef_deploy_user_full_name = "${var.chef_server_deploy_user_full_name}"
    chef_deploy_user_email = "${var.chef_server_deploy_user_email}"
    chef_deploy_user_password = "${var.chef_server_deploy_user_password}"
    chef_org_name = "${var.chef_server_org_name}"
    chef_org_full_name = "${var.chef_server_org_full_name}"
    secrets_bucket = "${aws_s3_bucket.devops-demo-secrets.bucket}"
    aws_region = "${aws_s3_bucket.devops-demo-secrets.region}"
  }
}

resource "aws_instance" "chef-server" {
  instance_type = "t2.medium"
  ami = "${lookup(var.aws_amis, var.aws_region)}"
  iam_instance_profile = "${aws_iam_instance_profile.secrets_read_write.name}"
  subnet_id = "${aws_subnet.public.id}"
  private_ip = "10.0.0.100"
  associate_public_ip_address = true
  source_dest_check = true
  user_data = "${template_file.chef-server-userdata.rendered}"
  key_name = "devops-key"
  vpc_security_group_ids = [
    "${aws_security_group.public_egress.id}",
    "${aws_security_group.allow_ssh.id}",
    "${aws_security_group.chef_server.id}"
  ]
  tags {
    Name = "devops-demo-chef-server"
  }
}

# Add an A record to route-53
resource "aws_route53_record" "chef-server" {
  zone_id = "${aws_route53_zone.internal.id}"
  name = "chef-server"
  type = "A"
  ttl = "300"
  records = [
    "${aws_instance.chef-server.private_ip}"]
}

resource "template_file" "chef-server-in-addr-arpa-hostname" {
  template = "${file("in-addr-arpa-hostname.tpl")}"
  vars {
    ipv4 = "${aws_instance.chef-server.private_ip}"
  }
}

# Add inverse DNS record to route-53
resource "aws_route53_record" "chef-server-inverse" {
  zone_id = "${aws_route53_zone.reverse.id}"
  name = "${template_file.chef-server-in-addr-arpa-hostname.rendered}"
  type = "PTR"
  ttl = "300"
  records = [
    "chef-server.${aws_route53_zone.internal.name}."
    ]
}

resource "aws_route53_record" "chef_server_public" {
  count = "${replace(replace(replace(var.route53_public_hosted_zone_id, "/(?:none)|(.*)/", "$1"), "/^.+$/", "1"), "/$^/", "0")}"
  zone_id = "${var.route53_public_hosted_zone_id}"
  name = "chef-server"
  type = "CNAME"
  ttl = "60"
  records = [
    "${aws_instance.chef-server.public_dns}"
  ]
}
