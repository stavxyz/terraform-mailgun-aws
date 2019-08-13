/*
 * Module: tf_mailgun_aws
 *
 * Outputs:
 *   - zone_id
 *   - name_servers
 */

# Be sure to check this output and set using the UpdateDomainNameservers API
output "aws_name_servers" {
  value = data.aws_route53_zone.selected[0].name_servers
}

output "aws_zone_id" {
  value = element(concat(data.aws_route53_zone.selected.*.zone_id, [""]), 0)
}

output "cloudflare_zone_name" {
  value = length(data.cloudflare_zones.selected.*.zones) > 0 ? element(concat(data.cloudflare_zones.selected.*.zones, [""]), 0) : ""
}

output "cloudflare_zone_id" {
  #value = "${element(concat(data.cloudflare_zones.selected.*.zones[0].id, list("")), 0)}"
  #value = "${element(concat(data.cloudflare_zones.selected.*.zones, chunklist(list(""), 1)), 0)}.id"
  value = flatten(
    slice(
      data.cloudflare_zones.selected.*.zones,
      0,
      length(data.cloudflare_zones.selected.*.zones) - max(length(data.cloudflare_zones.selected.*.zones) - 1, 0),
    ),
  )
}

output "cloudflare_name_servers" {
  #value = "${element(concat(data.cloudflare_zones.selected.*.zones, chunklist(list(""), 1)), 0)}"
  #value = "${flatten(slice(data.cloudflare_zones.selected.*.zones, 0, 1))}[0].name_servers"
  value = flatten(
    slice(
      data.cloudflare_zones.selected.*.zones,
      0,
      length(data.cloudflare_zones.selected.*.zones) - max(length(data.cloudflare_zones.selected.*.zones) - 1, 0),
    ),
  )
}

############################
##### old aliases ##########
############################

output "zone_id" {
  description = "DEPRECATED, USE PROVIDER SPECIFIC VALUE (unless we can figure out conditionals in the output value."
  value       = element(concat(data.aws_route53_zone.selected.*.zone_id, [""]), 0)
}

output "name_servers" {
  value = flatten(data.aws_route53_zone.selected.*.name_servers)
}

