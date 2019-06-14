/*
 * Module: tf_mailgun_aws
 *
 * Outputs:
 *   - zone_id
 *   - name_servers
 */

# Be sure to check this output and set using the UpdateDomainNameservers API
output "aws_name_servers" {
  value = "${element(data.aws_route53_zone.selected.*.name_servers, 0)}"
}

output "aws_zone_id" {
  value = "${element(concat(data.aws_route53_zone.selected.*.zone_id, list("")), 0)}"
}

output "cloudflare_zone_name" {
  #value = "${element(concat(data.cloudflare_zones.selected.*.zones, list("")), 0)}"
  value = "${element(data.cloudflare_zones.selected.*.zones, 0)}.name"
}

output "cloudflare_zone_id" {
  #value = "${element(concat(data.cloudflare_zones.selected.*.zones[0].id, list("")), 0)}"
  value = "${element(data.cloudflare_zones.selected.*.zones, 0)}.id"
}

output "cloudflare_name_servers" {
  #value = "${element(concat(data.cloudflare_zones.selected.*.zones, chunklist(list(""), 1)), 0)}"
  value = "${element(data.cloudflare_zones.selected.*.zones, 0)}.name_servers"
}


############################
##### old aliases ##########
############################

output "zone_id" {
  description = "DEPRECATED, USE PROVIDER SPECIFIC VALUE (unless we can figure out conditionals in the output value."
  value = "${element(concat(data.aws_route53_zone.selected.*.zone_id, list("")), 0)}"
}


output "name_servers" {
  value = "${element(data.aws_route53_zone.selected.*.name_servers, 0)}"
}

