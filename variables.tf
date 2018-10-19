variable "mailgun_smtp_password" {
  type = "string"
}

variable "domain" {
  type = "string"
}

variable "mailgun_spam_action" {
  type = "string"
  default = "tag"
  description = "Spam filter behavior, (tag or disabled)."
}

variable "mailgun_wildcard" {
  default = true
  description = "Determines whether the domain will accept email for sub-domains."
}

variable "mailgun_set_mx_for_inbound" {
  default = 1
  description = "Affects terraform-mailgun-aws module behavior. Set to false or 0 to prevent this module from setting mailgun.org MX records on your Route53 Hosted Zone. See more information about how terraform handles booleans here: https://www.terraform.io/docs/configuration/variables.html"
}

variable "zone_id" {
  default = 0
  description = "You probaly want to set this variable if 1) You are using an existing Route53 Zone 2) You don't want to delete and recreate that route53 zone and/or 3) You don't want to `terraform import` your existing Route53 Zone into this module. (Instructions for that are in the README). If this zone id is set, terrafrom-mailgun-aws will use this existing zone *instead of creating one for you*."
}

variable "record_ttl" {
  default = 300
  description = "Lifespan of DNS records"
}
