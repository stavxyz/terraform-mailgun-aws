/*
 * Module: tf_mailgun_aws
 *
 * This template creates the following resources
 *   - A Mailgun domain
 *   - An AWS Route53 Zone
 *   - AWS Route53 Records:
 *     - SPF, DKIM, CNAME, MX
 *
 * If using an existing Route53 Zone, import the zone
 * into terraform:
 * $ terraform import module.INSTANCE.aws_route53_zone.this <your_route53_zone_id>
 *
 * where INSTANCE is the name you choose as in
 *
 * module "INSTANCE" {
 *   source = "github.com/samstav/tf_mailgun_aws"
 * }
 *
 */

resource "mailgun_domain" "this" {
  name          = "${var.domain}"
  smtp_password = "${var.mailgun_smtp_password}"
  spam_action   = "${var.mailgun_spam_action}"
  wildcard      = "${var.mailgun_wildcard}"

  # prevent_destroy is on because I have had issues
  # with mailgun disabling my domain resource when
  # terraform re-creates it
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_zone" "this" {
  # This hack deals with https://github.com/hashicorp/terraform/issues/8511
  name = "${element( split("","${var.domain}"), "${ length("${var.domain}") -1 }") == "." ? var.domain : "${var.domain}."}"
  comment       = "Domain with mailgun mail managed by terraform."
  force_destroy = false
}

resource "aws_route53_record" "mailgun_sending_record_0" {
  zone_id = "${aws_route53_zone.this.zone_id}"
  name    = "${mailgun_domain.this.sending_records.0.name}."
  ttl     = "${var.record_ttl}"
  type    = "${mailgun_domain.this.sending_records.0.record_type}"
  records = ["${mailgun_domain.this.sending_records.0.value}"]
}

resource "aws_route53_record" "mailgun_sending_record_1" {
  zone_id = "${aws_route53_zone.this.zone_id}"
  name    = "${mailgun_domain.this.sending_records.1.name}."
  ttl     = "${var.record_ttl}"
  type    = "${mailgun_domain.this.sending_records.1.record_type}"
  records = ["${mailgun_domain.this.sending_records.1.value}"]
}

resource "aws_route53_record" "mailgun_sending_record_2" {
  zone_id = "${aws_route53_zone.this.zone_id}"
  name    = "${mailgun_domain.this.sending_records.2.name}."
  ttl     = "${var.record_ttl}"
  type    = "${mailgun_domain.this.sending_records.2.record_type}"
  records = ["${mailgun_domain.this.sending_records.2.value}"]
}

resource "aws_route53_record" "mailgun_receiving_records_mx" {
  zone_id = "${aws_route53_zone.this.zone_id}"
  name = ""
  ttl     = "${var.record_ttl}"
  type = "MX"
  records = [
    "${mailgun_domain.this.receiving_records.0.priority} ${mailgun_domain.this.receiving_records.0.value}",
    "${mailgun_domain.this.receiving_records.1.priority} ${mailgun_domain.this.receiving_records.1.value}"
  ]
}
