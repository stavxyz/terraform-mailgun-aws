/*
 * Module: tf_mailgun_aws
 *
 * Outputs:
 *   - zone_id
 *   - name_servers
 */

# Be sure to check this output and set using the UpdateDomainNameservers API
output "aws_name_servers" {
  value = "${element(concat(data.aws_route53_zone.selected.*.name_servers, list("")), 0)}"
}

output "aws_zone_id" {
  value = "${element(concat(data.aws_route53_zone.selected.*.zone_id, list("")), 0)}"
}

output "cloudflare_name_servers" {
  value = "${element(concat(data.cloudflare_zones.selected.*.name_servers, list("")), 0)}"
}

output "cloudflare_zone_name" {
  value = "${element(concat(data.cloudflare_zones.selected.*.name, list("")), 0)}"
}

output "cloudflare_zone_id" {
  value = "${element(concat(data.cloudflare_zones.selected.*.id, list("")), 0)}"
}

############################
##### old aliases ##########
############################

output "zone_id" {
  description = "DEPRECATED, USE PROVIDER SPECIFIC VALUE (unless we can figure out conditionals in the output value."
  value = "${element(concat(data.aws_route53_zone.selected.*.zone_id, list("")), 0)}"
}


output "name_servers" {
  description = "DEPRECATED, USE PROVIDER SPECIFIC VALUE (unless we can figure out conditionals in the output value."
  value = "${element(concat(data.aws_route53_zone.selected.*.name_servers, list("")), 0)}"
}
