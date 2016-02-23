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
    "${aws_security_group.allow_ssh.id}"
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
