variable "region" {}
variable "atlas_username" {}
variable "atlas_environment" {}
variable "atlas_token" {}
variable "name" {}
variable "vpc_cidr" {}
variable "public_subnets" {}
variable "azs" {}
variable "app_instance_type" {}
variable "bastion_instance_type" {}

provider "aws" {
  region = "${var.region}"
}

atlas {
  name = "${var.atlas_username}/${var.atlas_environment}"
}

/*
resource "atlas_artifact" "app" {
  name = "${var.atlas_username}/${var.name}-app"
  type = "amazon.ami"
}
*/

resource "aws_vpc" "vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags { Name = "${var.name}" }
  lifecycle { create_before_destroy = true }
}

resource "aws_internet_gateway" "public" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags { Name = "${var.name}" }
}

resource "aws_subnet" "public" {
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${element(split(",", var.public_subnets), count.index)}"
  availability_zone = "${element(split(",", var.azs), count.index)}"
  count             = "${length(split(",", var.public_subnets))}"

  tags { Name = "${var.name}.${element(split(",", var.azs), count.index)}" }

  map_public_ip_on_launch = true
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.public.id}"
  }
  tags { Name = "${var.name}.${element(split(",", var.azs), count.index)}" }
}

resource "aws_route_table_association" "public" {
  count          = "${length(split(",", var.public_subnets))}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_security_group" "bastion" {
  name        = "${var.name}"
  vpc_id      = "${aws_vpc.vpc.id}"
  description = "Bastion security group"

  tags { Name = "${var.name}-bastion" }
  lifecycle { create_before_destroy = true }
}

resource "aws_security_group_rule" "bastion_egress" {
  security_group_id = "${aws_security_group.bastion.id}"
  type              = "egress"

  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_all_from_vpc" {
  security_group_id = "${aws_security_group.bastion.id}"
  type              = "ingress"

  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["${var.vpc_cidr}"]
}

resource "aws_security_group_rule" "allow_ssh_from_world" {
  security_group_id = "${aws_security_group.bastion.id}"
  type              = "ingress"

  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["0.0.0.0/0"]
}

module "ami" {
  source        = "github.com/terraform-community-modules/tf_aws_ubuntu_ami/ebs"
  instance_type = "${var.bastion_instance_type}"
  region        = "${var.region}"
  distribution  = "trusty"
}

resource "aws_key_pair" "key" {
  key_name = "${var.name}"
  public_key = "${file("files/${var.name}.pub")}"
}

resource "aws_instance" "bastion" {
  ami                    = "${module.ami.ami_id}"
  instance_type          = "${var.bastion_instance_type}"
  key_name               = "${aws_key_pair.key.key_name}"
  subnet_id              = "${element(split(",", var.public_subnets), count.index)}"
  vpc_security_group_ids = ["${aws_security_group.bastion.id}"]

  tags { Name = "${var.name}-bastion" }
}

resource "aws_security_group" "app" {
  name   = "${var.name}"
  vpc_id = "${aws_vpc.vpc.id}"
  description = "Windows app security group"

  tags { Name = "${var.name}-app" }
  lifecycle { create_before_destroy = true }
}

resource "aws_security_group_rule" "app_ingress" {
  security_group_id = "${aws_security_group.app.id}"
  type              = "ingress"

  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "app_egress" {
  security_group_id = "${aws_security_group.app.id}"
  type              = "egress"

  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_instance" "app" {
  # ami                    = "${atlas_artifact.app.metadata_full.region-us-east-1}"
  ami                    = "ami-f70cdd9c"
  instance_type          = "${var.app_instance_type}"
  key_name               = "${aws_key_pair.key.key_name}"
  subnet_id              = "${element(split(",", var.public_subnets), count.index)}"
  vpc_security_group_ids = ["${aws_security_group.app.id}"]

  tags { Name = "${var.name}-app" }
}
