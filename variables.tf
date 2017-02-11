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
  description = "Affects tf_mailgun_aws module behavior. Set to false or 0 to prevent this module from setting mailgun.org MX records on your Route53 Hosted Zone. See more information about how terraform handles booleans here: https://www.terraform.io/docs/configuration/variables.html"
}

variable "record_ttl" {
  default = 300
  description = "Lifespan of DNS records"
}
