# tf_mailgun_aws
A Terraform module for creating a Mailgun domain, Route53 Zone, and corresponding DNS records

This project automates the following setup, on AWS Route 53:

https://documentation.mailgun.com/quickstart-sending.html#send-with-smtp-or-api

# A note on terraform state

I prefer using [s3 remote state for terraform](https://www.terraform.io/docs/state/remote/s3.html) instead of leaving state on your local machine. In addition to being able to make infra changes via CI (e.g. CircleCI), this has the added benefit of easy tf state rollbacks via S3 bucket versioning.

Bootsrap your remote state bucket like so:

```
$ terraform plan -out=remote-config.plan -target=aws_s3_bucket.tf_remote_config_bucket
$ terraform apply remote-config.plan
```

Otherwise, if you want to use an existing s3 bucket to store your terraform state:

```
# instead of the foo-dot-com suffix, if your domain
# is johnsmith.net use terraform-state-johnsmith-dot-net
$ terraform import aws_s3_bucket.bucket terraform-state-foo-dot-com
```

Terraform autoloads `terraform.tfvars.json` variable files as well,
as of https://github.com/hashicorp/terraform/pull/1093
so run the tfvars command and it will be written for you:

```
./main.py tfvars foo.com
```

### Using an existing route53 zone for your domain

To use an existing zone, instead of letting this tf module create the zone,
you need to import your zone (by id) *into the mailgun-aws tf module*:

```
$ terraform import module.INSTANCE.aws_route53_zone.this <your_route53_zone_id>
```

where INSTANCE is the name you choose as in

```hcl
module "INSTANCE" {
source = "github.com/samstav/tf_mailgun_aws"
}
```

Then

```
terraform plan -out=my.plan
terraform apply my.plan
```

# Nameservers

Make sure the nameservers (the values on your NS record in your zone) match the nameservers configured at your registrar.
