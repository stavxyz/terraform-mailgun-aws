# tf_mailgun_aws  
[![Circle CI](https://circleci.com/gh/samstav/tf_mailgun_aws/tree/master.svg?style=shield)](https://circleci.com/gh/samstav/tf_mailgun_aws)

A Terraform module for creating a Mailgun domain, Route53 Zone, and corresponding DNS records

This project automates the following setup, on AWS Route 53:

https://documentation.mailgun.com/quickstart-sending.html#verify-your-domain


### Prerequisites

#### mailgun

You'll need your Mailgun API Key, found in your control panel homepage. 

Sign up: https://mailgun.com/signup  
Control Panel: https://mailgun.com/cp

#### terraform

https://www.terraform.io/downloads.html

or mac users can `brew install terraform`

The included script can help you configure your remote state.

```bash
# this will perform a dry-run, showing you the command
./main.py tf-remote-config <your-domain.com> --dry-run
```

Run the same, but without `--dry-run`, to configure terraform to use remote state. This will also create your s3 bucket if it doesn't already exist.

Mailgun domains do not support `terraform import`, so you need to let this module
create the mailgun domain for you, otherwise you end up manually editing your
state file which probably won't end well.

### module usage

Utilize this module in one or more of your tf files:

```hcl
provider "aws" {
  region = "us-east-1"
}

module "mailer" {
  source                = "github.com/samstav/tf_mailgun_aws"
  domain                = "${var.domain}"
  mailgun_smtp_password = "${var.mailgun_smtp_password}"
}
```

*Before running your plan, fetch the module with `terraform get`*


### Using an existing route53 zone for your domain

To use an existing zone, instead of letting this tf module create the zone,
you need to import your zone (by id) *into the mailgun-aws tf module*:

```bash
$ terraform import module.INSTANCE.aws_route53_zone.this <your_route53_zone_id>
```

where INSTANCE is the name you choose as in

```hcl
module "INSTANCE" {
  source = "github.com/samstav/tf_mailgun_aws"
}
```

To find the zone id for your existing Route53 Hosted Zone:

```bash
$ aws route53 list-hosted-zones-by-name --dns-name your-domain.com
```

Then

```bash
$ terraform plan -out=my.plan
$ terraform apply my.plan
```

### Nameservers

Make sure the nameservers (the values on your NS record in your zone) match the nameservers configured at your registrar.
