# terraform-mailgun-aws
[![Circle CI](https://circleci.com/gh/samstav/terraform-mailgun-aws/tree/master.svg?style=shield)](https://circleci.com/gh/samstav/terraform-mailgun-aws)
[![Terraform](https://img.shields.io/badge/terraform-%3E=0.8.0-822ff7.svg)](https://www.terraform.io/)

A Terraform module for creating a Mailgun domain, Route53 Zone, and corresponding DNS records

This project automates the following setup on AWS Route 53:

https://documentation.mailgun.com/quickstart-sending.html#verify-your-domain

Sending & Tracking DNS Records created by this module:  

| Type | Value | Purpose |
| --- | --- | ---|
| TXT | “v=spf1 include:mailgun.org ~all” | SPF (Required) |
| TXT | [_This value is dynamic_](https://documentation.mailgun.com/quickstart-sending.html#add-sending-tracking-dns-records)| DKIM (Required) |
| CNAME | “mailgun.org” | Tracking (Optional) |

Receiving MX Records Records created by this module (optional, see use of `mailgun_set_mx_for_inbound` variable below) :  

| Type | Value | Purpose |
| --- | --- | ---|
| MX | mxa.mailgun.org | Receiving (Optional) |
| MX | mxb.mailgun.org	| Receiving (Optional) |

From the [mailgun docs](https://documentation.mailgun.com/quickstart-receiving.html#add-receiving-mx-records):

> Do not configure Receiving MX DNS records if you already have another provider handling inbound mail delivery for your domain (e.g. Gmail). Instead we recommend using a subdomain on Mailgun (e.g. mg.yourdomain.com)

To disable the creation of the MX records, set [the terraform variable `mailgun_set_mx_for_inbound`](https://github.com/samstav/terraform-mailgun-aws/blob/6c58d8bc8699866337816f3f583c97bb40105423/variables.tf#L20-L23) to `false`. 

## Prerequisites

### mailgun

You'll need your Mailgun API Key, found in your control panel homepage. 

Sign up: https://mailgun.com/signup  
Control Panel: https://mailgun.com/cp

_Mailgun domains do not support `terraform import`, so *you need to let this module
create the mailgun domain for you*, otherwise you end up manually editing your
state file which probably won't end well._


### terraform

https://www.terraform.io/downloads.html

or mac users can `brew install terraform`

## Usage

Utilize this module in one or more of your tf files:

### variables file, `terraform.tfvars`  

```bash
aws_region = "us-east-1"
domain = "big-foo.com"
mailgun_api_key = "key-***********"
mailgun_smtp_password = "*********"
```

### terraform file, e.g. `main.tf`  

```hcl
provider "aws" {
  region = "${var.aws_region}"
}

provider "mailgun" {
  api_key = "${var.mailgun_api_key}"
}

variable "aws_region" {}
variable "domain" {}
variable "mailgun_api_key" {}
variable "mailgun_smtp_password" {}

module "mailer" {
  source                = "github.com/samstav/terraform-mailgun-aws"
  domain                = "${var.domain}"
  mailgun_smtp_password = "${var.mailgun_smtp_password}"
}

```

__*Before running your plan, [fetch the module with `terraform get -update`](https://www.terraform.io/docs/commands/get.html)*__


Once your definition(s) are complete:

```bash
# This downloads and installs modules needed for your configuration.
# See `terraform get --help` for more info
$ terraform get -update
# This generates an execution plan for terraform. To save this to a file you need to supply -out.
# To generate a plan *only* for this module, use -target=module.mailer
# See `terraform plan --help` for more info.
$ terraform plan -out=mailer.plan
# This builds or changes infrastructure according to the terraform execution plan.
# See `terraform apply --help` for more info. 
$ terraform apply mailer.plan
```

To [pin your configuration to a specific version of this module, use the `?ref` param](https://www.terraform.io/docs/modules/sources.html#ref) and change your `source` line to something like this:

```hcl
  source = "github.com/samstav/terraform-mailgun-aws?ref=v1.1.0"
```

See [releases](https://github.com/samstav/terraform-mailgun-aws/releases). 


### When using an _existing_ Route53 Zone

There are two different approaches when using an existing Route53 Zone with this module. The first, and simplest approach, is to set the `zone_id` variable. This module detects the presence of this value and will presume the existence of your Route53 zone. It will use then use (and modify the records on that zone) rather than creating a new zone for you.

The second approach is to import your existing Route53 [zone](https://www.terraform.io/docs/providers/aws/r/route53_zone.html) (by id) *into the `terraform-mailgun-aws` module* [using `terraform import`](https://www.terraform.io/docs/import/). The fundamental difference with this approach is that your zone will now be tracked and managed as a resource component of this module. Every terraform run (plan/apply) will then check the existence and state (configuration) of the zone. This has some advantages, primarily in the case that you want terraform to destroy and/or re-create the zone without needing to hard-code the new Route53 Zone ID.

To import your existing zone into this module:

```
$ terraform import module.mailer.aws_route53_zone.this[0] <your_route53_zone_id>
```

_(The `[0]` is needed because it is a "conditional resource" and you must refer to the 'count' index when importing, which is always [0])_
 
The `mailer` portion is the name you choose for the module instance, e.g.:
 
```hcl
module "mailer" {
  source = "github.com/samstav/terraform-mailgun-aws"
}
```

To find the zone id for your existing Route53 Hosted Zone:

```bash
$ aws route53 list-hosted-zones-by-name --dns-name big-foo.com
```

### To refer to the Route53 zone created/used by the module

[This module outputs](https://github.com/samstav/terraform-mailgun-aws/blob/master/outputs.tf) the Route53 Zone ID, as well as the NS record values (the nameservers):

To refer to these outputs, use `"${module.mailer.zone_id}"` or `"${module.mailer.name_servers}"`

```hcl

...

resource "aws_route53_record" "root" {
  # refer to your zone id like so
  zone_id = "${module.mailer.zone_id}"
  name = "${var.domain}"
  type = "A"
  alias {
    name = "s3-website-us-east-1.amazonaws.com."
    zone_id = "********"
    evaluate_target_health = true
  }
}
```

### Adding a route in mailgun to forward all mail

Route resources are not available in the [mailgun terraform provider](https://www.terraform.io/docs/providers/mailgun/), so we do it with [the included script](https://github.com/samstav/terraform-mailgun-aws/blob/master/main.py).

```
$ ./main.py create-route big-foo.com --forward bigfoo@gmail.com
{
  "message": "Route has been created",
  "route": {
    "actions": [
      "forward(\"bigfoo@gmail.com\")"
    ],
    "created_at": "Sun, 01 Jan 2017 18:21:16 GMT",
    "description": "Forward all mailgun domain email to my specified forwarding location(s).",
    "expression": "match_recipient(\".*@big-foo.com\")",
    "id": "84jfnnb3oepoj85jhbaae4f6",
    "priority": 1
  }
}
```

See `./main.py create-route --help` for more options on creating routes. 

### Nameservers

Make sure the nameservers (the values on your NS record in your zone) match the nameservers configured at your registrar.
