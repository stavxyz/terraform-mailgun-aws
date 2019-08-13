# TODO: expose configuration of zone
#  - type (can be "full" or "partial")
#  - plan ?
#  - jumpstart (if true, cloudflare will discover and import existing dns records)
#  - paused (if true, traffic will bypass cloudflare)

variable "cloudflare_zone_type" {
  type        = string
  default     = "full"
  description = "A full zone implies that DNS is hosted with Cloudflare. A partial zone is typically a partner-hosted zone or a CNAME setup. Valid values: full, partial. Default is full."
}

variable "cloudflare_zone_jump_start" {
  default     = "false"
  description = "Boolean of whether to scan for DNS records on creation. Ignored after zone is created. Default: false."
}

variable "cloudflare_zone_paused" {
  default     = "false"
  description = "Boolean of whether this zone is paused (traffic bypasses Cloudflare). Default: false."
}

variable "zone_name" {
  default = 0
}

data "cloudflare_zones" "selected" {
  # if this module created/manages the zone, then refer to its Zone ID, otherwise
  # refer to the Zone (by name) passed into this module
  # Note: Unlike aws r53, Cloudflare zone data source does not accept zone id as a filter
  count = var.dns_provider == "cloudflare" ? 1 : 0
  filter {
    # This is a regular expression, so prepend a ^ and append a $ to match an explicit zone
    name = var.zone_name == "0" ? element(concat(cloudflare_zone.this.*.id, [""]), 0) : format("^%s$", var.zone_name)
  }
}

# Will probably have to select like:
#  -> ${element(concat(data.cloudflare_zones.selected.*.zones[0], list("")), 0).name}
#  -> ${element(concat(data.cloudflare_zones.selected.*.zones[0], list("")), 0).id}

resource "cloudflare_zone" "this" {
  # If zone_name is its default (0) then create a new zone, else, use zone passed in
  count      = var.dns_provider == "cloudflare" && var.zone_name == "0" ? 1 : 0
  zone       = var.domain
  jump_start = var.cloudflare_zone_jump_start
  type       = var.cloudflare_zone_type
  paused     = var.cloudflare_zone_paused
}

resource "cloudflare_record" "mailgun_sending_record_0" {
  domain = "${element(concat(data.cloudflare_zones.selected[0].zones, [""]), 0)}.name"
  name   = "${mailgunv3_domain.this.sending_records[0].name}."
  ttl    = var.record_ttl
  type   = mailgunv3_domain.this.sending_records[0].record_type
  value  = mailgunv3_domain.this.sending_records[0].value
  count  = var.dns_provider == "cloudflare" ? 1 : 0
}

resource "cloudflare_record" "mailgun_sending_record_1" {
  domain = "${element(concat(data.cloudflare_zones.selected[0].zones, [""]), 0)}.name"
  name   = "${mailgunv3_domain.this.sending_records[1].name}."
  ttl    = var.record_ttl
  type   = mailgunv3_domain.this.sending_records[1].record_type
  value  = mailgunv3_domain.this.sending_records[1].value
  count  = var.dns_provider == "cloudflare" ? 1 : 0
}

resource "cloudflare_record" "mailgun_sending_record_2" {
  domain = "${element(concat(data.cloudflare_zones.selected[0].zones, [""]), 0)}.name"
  name   = "${mailgunv3_domain.this.sending_records[2].name}."
  ttl    = var.record_ttl
  type   = mailgunv3_domain.this.sending_records[2].record_type
  value  = mailgunv3_domain.this.sending_records[2].value
  count  = var.dns_provider == "cloudflare" ? 1 : 0
}

resource "cloudflare_record" "mailgun_receiving_records_mx" {
  # Some users may have another provider handling inbound
  # mail and just want their domain verified and setup for outbound
  # Use the count trick to make this optional.
  domain = "${element(concat(data.cloudflare_zones.selected[0].zones, [""]), 0)}.name"
  name   = ""
  ttl    = var.record_ttl
  type   = "MX"
  value = format(
    "%s %s",
    mailgunv3_domain.this.receiving_records[0].priority,
    mailgunv3_domain.this.receiving_records[0].value,
  )
  count = var.dns_provider == "cloudflare" ? 1 : 0
}

