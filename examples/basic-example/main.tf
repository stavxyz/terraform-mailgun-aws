provider "aws" {
  region = "${var.aws_region}"
}

provider "mailgun" {
  api_key = "${var.mailgun_api_key}"
}

variable "aws_region" {}
variable "domain" {}
variable "mailgun_api_key" {}
variable "mailgun_smtp_password" {}

module "mailer" {
  source                = "../../"
  domain                = "${var.domain}"
  mailgun_smtp_password = "${var.mailgun_smtp_password}"
}
