# tf_mailgun_aws
A Terraform module for creating a Mailgun domain, Route53 Zone, and corresponding DNS records

This project automates the following setup, on AWS Route 53:

https://documentation.mailgun.com/quickstart-sending.html#send-with-smtp-or-api

### get terraform

https://www.terraform.io/downloads.html

or mac users can `brew install terraform`

### A note on terraform state

I prefer using [s3 remote state for terraform](https://www.terraform.io/docs/state/remote/s3.html) instead of leaving state on your local machine. In addition to being able to make infra changes via CI (e.g. CircleCI), this has the added benefit of easy tf state rollbacks via S3 bucket versioning.

Bootstrap your remote state bucket (by creating it, targeted using the `-target` option):

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

The included script can help you configure your remote state, once your bucket is created.

```
# this will perform a dry-run, showing you the command
./main.py tf-remote-config --dry-run
```

Run the same, without `--dry-run` to configure terraform to use remote state.

Terraform autoloads `terraform.tfvars.json` variable files as well,
as of https://github.com/hashicorp/terraform/pull/1093
so run the tfvars command and it will be written for you:

```
./main.py tfvars foo.com
```

Mailgun domains do not support `terraform import`, so you need to let this module
create the mailgun domain for you, otherwise you end up manually editing your
state file which probably won't end well.

### module usage

Utilize this module in one or more of your tf files:

```hcl
module "mailer" {
  source                = "github.com/samstav/tf_mailgun_aws"
  domain                = "${var.domain}"
  mailgun_smtp_password = "${var.mailgun_smtp_password}"
}
```

Before running your plan, fetch the module with `terraform get`


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
