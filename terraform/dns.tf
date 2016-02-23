resource "aws_route53_zone" "internal" {
  name = "internal.devops-demo.co.uk"
  vpc_id = "${aws_vpc.devops-demo.id}"
}

resource "aws_route53_zone" "reverse" {
  name = "0.10.in-addr.arpa."
  vpc_id = "${aws_vpc.devops-demo.id}"
}

resource "aws_vpc_dhcp_options" "internal" {
  domain_name_servers = ["AmazonProvidedDNS"]
  domain_name = "${aws_route53_zone.internal.name}"
}

resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id = "${aws_vpc.devops-demo.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.internal.id}"
}