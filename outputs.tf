/*
 * Module: tf_mailgun_aws
 *
 * Outputs:
 *   - zone_id
 *   - name_servers
 */

output "zone_id" {
  value = "${aws_route53_zone.this.zone_id}"
}


# Be sure to check this output and set using the UpdateDomainNameservers API
output "name_servers" {
  value = "${aws_route53_zone.this.name_servers}"
}
