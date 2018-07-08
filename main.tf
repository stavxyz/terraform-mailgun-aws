/*
 * Module: terraform-mailgun-aws
 *
 * This template creates the following resources
 *   - A Mailgun domain
 *   - An AWS Route53 Zone
 *   - AWS Route53 Records:
 *     - SPF, DKIM, CNAME, MX
 *
 * The MX records are optional, to disable set the variable mailgun_set_mx_for_inbound to false.
 *
 * If using an existing Route53 Zone, perform a terraform import on your zone:
 *
 * $ terraform import module.my_instance.aws_route53_zone.this <your_route53_zone_id>
 *
 * where the 'my_instance' portion is the name you choose:
 *
 * module "my_instance" {
 *   source = "github.com/samstav/terraform-mailgun-aws"
 * }
 *
 */


# This module uses conditionals and therefore needs at least 0.8.0
# https://github.com/hashicorp/terraform/blob/master/CHANGELOG.md#080-december-13-2016

terraform {
  required_version = ">= 0.8.0"
}


resource "mailgun_domain" "this" {
  name          = "${var.domain}"
  smtp_password = "${var.mailgun_smtp_password}"
  spam_action   = "${var.mailgun_spam_action}"
  wildcard      = "${var.mailgun_wildcard}"

  # prevent_destroy is on because I have seen issues
  # with mailgun disabling my domain resource when
  # terraform re-creates it. This results in needing
  # to open a ticket with mailgun and is no fun :)

  lifecycle {
    prevent_destroy = true
  }

}

data "aws_route53_zone" "selected" {
  zone_id = "${var.zone_id == "0" ? "${element(concat(aws_route53_zone.this.*.zone_id, list("")), 0) }" : var.zone_id}"
}

resource "aws_route53_zone" "this" {
  # If zone_id is its default (0) then dont create a zone
  count = "${var.zone_id == "0" ? 1 : 0}"
  # This hack deals with https://github.com/hashicorp/terraform/issues/8511
  name          = "${element( split("","${var.domain}"), "${ length("${var.domain}") -1 }") == "." ? var.domain : "${var.domain}."}"
  comment       = "Zone managed by terraform with mailgun mail and created by github.com/samstav/terraform-mailgun-aws"
  force_destroy = false
}

resource "aws_route53_record" "mailgun_sending_record_0" {
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "${mailgun_domain.this.sending_records.0.name}."
  ttl     = "${var.record_ttl}"
  type    = "${mailgun_domain.this.sending_records.0.record_type}"
  records = ["${mailgun_domain.this.sending_records.0.value}"]
}


resource "aws_route53_record" "mailgun_sending_record_1" {
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "${mailgun_domain.this.sending_records.1.name}."
  ttl     = "${var.record_ttl}"
  type    = "${mailgun_domain.this.sending_records.1.record_type}"
  records = ["${mailgun_domain.this.sending_records.1.value}"]
}

resource "aws_route53_record" "mailgun_sending_record_2" {
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "${mailgun_domain.this.sending_records.2.name}."
  ttl     = "${var.record_ttl}"
  type    = "${mailgun_domain.this.sending_records.2.record_type}"
  records = ["${mailgun_domain.this.sending_records.2.value}"]
}

resource "aws_route53_record" "mailgun_receiving_records_mx" {
  # Some users may have another provider handling inbound
  # mail and just want their domain verified and setup for outbound
  # Use the count trick to make this optional.
  count = "${var.mailgun_set_mx_for_inbound ? 1 : 0}"
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name = ""
  ttl     = "${var.record_ttl}"
  type = "MX"
  records = [
    "${mailgun_domain.this.receiving_records.0.priority} ${mailgun_domain.this.receiving_records.0.value}",
    "${mailgun_domain.this.receiving_records.1.priority} ${mailgun_domain.this.receiving_records.1.value}"
  ]
}
