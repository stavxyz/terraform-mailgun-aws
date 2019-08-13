data "aws_route53_zone" "selected" {
  # if this module created/manages the zone, then refer to its zone_id, otherwise
  # refer to the zone_id passed into this module
  zone_id = var.zone_id == "0" ? element(concat(aws_route53_zone.this.*.zone_id, [""]), 0) : var.zone_id
  count   = var.dns_provider == "aws" ? 1 : 0
}

resource "aws_route53_zone" "this" {
  # If zone_id is its default (0) then create a new zone, else, use zone_id passed in
  count = var.dns_provider == "aws" && var.zone_id == "0" ? 1 : 0

  # This hack deals with https://github.com/hashicorp/terraform/issues/8511
  name          = element(split("", var.domain), length(var.domain) - 1) == "." ? var.domain : "${var.domain}."
  comment       = "Zone managed by terraform with mailgun mail and created by github.com/samstav/terraform-mailgun-aws"
  force_destroy = false
}

resource "aws_route53_record" "mailgun_sending_record_0" {
  zone_id = element(data.aws_route53_zone.selected.*.zone_id, 0)
  name    = "${mailgunv3_domain.this.sending_records[0].name}."
  ttl     = var.record_ttl
  type    = mailgunv3_domain.this.sending_records[0].record_type
  records = [mailgunv3_domain.this.sending_records[0].value]
  count   = var.dns_provider == "aws" ? 1 : 0
}

resource "aws_route53_record" "mailgun_sending_record_1" {
  zone_id = element(data.aws_route53_zone.selected.*.zone_id, 0)
  name    = "${mailgunv3_domain.this.sending_records[1].name}."
  ttl     = var.record_ttl
  type    = mailgunv3_domain.this.sending_records[1].record_type
  records = [mailgunv3_domain.this.sending_records[1].value]
  count   = var.dns_provider == "aws" ? 1 : 0
}

resource "aws_route53_record" "mailgun_sending_record_2" {
  zone_id = element(data.aws_route53_zone.selected.*.zone_id, 0)
  name    = "${mailgunv3_domain.this.sending_records[2].name}."
  ttl     = var.record_ttl
  type    = mailgunv3_domain.this.sending_records[2].record_type
  records = [mailgunv3_domain.this.sending_records[2].value]
  count   = var.dns_provider == "aws" ? 1 : 0
}

resource "aws_route53_record" "mailgun_receiving_records_mx" {
  # Some users may have another provider handling inbound
  # mail and just want their domain verified and setup for outbound
  # Use the count trick to make this optional.
  count   = var.dns_provider == "aws" && var.mailgun_set_mx_for_inbound ? 1 : 0
  zone_id = element(data.aws_route53_zone.selected.*.zone_id, 0)
  name    = ""
  ttl     = var.record_ttl
  type    = "MX"
  records = [
    "${mailgunv3_domain.this.receiving_records[0].priority} ${mailgunv3_domain.this.receiving_records[0].value}",
    "${mailgunv3_domain.this.receiving_records[1].priority} ${mailgunv3_domain.this.receiving_records[1].value}",
  ]
}

