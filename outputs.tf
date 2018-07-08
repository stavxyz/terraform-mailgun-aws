/*
 * Module: tf_mailgun_aws
 *
 * Outputs:
 *   - zone_id
 *   - name_servers
 */

output "zone_id" {
  value = "${data.aws_route53_zone.selected.zone_id}"
}

# Be sure to check this output and set using the UpdateDomainNameservers API
output "name_servers" {
  value = "${data.aws_route53_zone.selected.name_servers}"
}
