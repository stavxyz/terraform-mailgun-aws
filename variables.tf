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

variable "record_ttl" {
  default = 300
  description = "Lifespan of DNS records"
}
