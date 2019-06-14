
# attributes: zones, id, name
data "cloudflare_zones" "selected" {
  # if this module created/manages the zone, then refer to its Zone ID, otherwise
  # refer to the Zone (by name) passed into this module
  # Note: Unlike aws r53, Cloudflare zone data source does not accept zone id as a filter
  filter {
    # This is a regular expression, so prepend a ^ and append a $ to match a single zone
    name = "${var.zone_name == "0" ? "${element(concat(cloudflare_zone.this.*.id, list("")), 0) }" : format("^%s$", var.zone_name)}"
  }
  count = "${var.dns_provider == "cloudflare" ? 1 : 0}"
}

# Will probably have to select like:
#  -> ${data.cloudflare_zones[0].id}
#  -> ${data.cloudflare_zones[0].name}

# TODO: expose configuration of zone
#  - type (can be "full" or "partial")
#  - plan ?
#  - jumpstart (if true, cloudflare will discover and import existing dns records)
#  - paused (if true, traffic will bypass cloudflare)

variable "cloudflare_zone_type" {
  type = "string"
  default = "full"
  description = "A full zone implies that DNS is hosted with Cloudflare. A partial zone is typically a partner-hosted zone or a CNAME setup. Valid values: full, partial. Default is full."
}

variable "cloudflare_zone_jump_start" {
  type = "bool"
  default = false
  description = "Boolean of whether to scan for DNS records on creation. Ignored after zone is created. Default: false."
}

variable "cloudflare_zone_paused" {
  type = "bool"
  default = false
  description = "Boolean of whether this zone is paused (traffic bypasses Cloudflare). Default: false."
}


resource "cloudflare_zone" "this" {
  # If zone_name is its default (0) then create a new zone, else, use zone passed in
  count = "${var.dns_provider == "cloudflare" && var.zone_name == "0" ? 1 : 0}"
  zone = "${var.domain}"
  jump_start = "${var.cloudflare_zone_jump_start}"
  type = "${var.cloudflare_zone_type}"
  paused = "${var.cloudflare_zone_paused}"
  force_destroy = false
}

resource "cloudflare_record" "mailgun_sending_record_0" {
  domain = ${data.cloudflare_zones[0].name}
  name    = "${mailgun_domain.this.sending_records.0.name}."
  ttl     = "${var.record_ttl}"
  type    = "${mailgun_domain.this.sending_records.0.record_type}"
  value = "${mailgun_domain.this.sending_records.0.value}"
  count = "${var.dns_provider == "cloudflare" ? 1 : 0}"
}

resource "cloudflare_record" "mailgun_sending_record_1" {
  domain = ${data.cloudflare_zones[0].name}
  name    = "${mailgun_domain.this.sending_records.1.name}."
  ttl     = "${var.record_ttl}"
  type    = "${mailgun_domain.this.sending_records.1.record_type}"
  value = "${mailgun_domain.this.sending_records.1.value}"
  count = "${var.dns_provider == "cloudflare" ? 1 : 0}"
}

resource "cloudflare_record" "mailgun_sending_record_2" {
  domain = ${data.cloudflare_zones[0].name}
  name    = "${mailgun_domain.this.sending_records.2.name}."
  ttl     = "${var.record_ttl}"
  type    = "${mailgun_domain.this.sending_records.2.record_type}"
  value = "${mailgun_domain.this.sending_records.2.value}"
  count = "${var.dns_provider == "cloudflare" ? 1 : 0}"
}

resource "cloudflare_record" "mailgun_receiving_records_mx" {
  # Some users may have another provider handling inbound
  # mail and just want their domain verified and setup for outbound
  # Use the count trick to make this optional.
  domain = ${data.cloudflare_zones[0].name}
  name = ""
  ttl     = "${var.record_ttl}"
  type    = "MX"
  value = format("%s %s", ${mailgun_domain.this.receiving_records.0.priority} ${mailgun_domain.this.receiving_records.0.value}),
  count = "${var.dns_provider == "cloudflare" ? 1 : 0}"
}
