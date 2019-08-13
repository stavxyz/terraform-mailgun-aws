#! /usr/bin/env python
from __future__ import print_function

import argparse
import collections
import json
import os
import shlex
import subprocess
import sys

import boto3
import botocore.exceptions
import requests

MAILGUN = 'https://api.mailgun.net/v3'
AWS_DEFAULT_REGION = boto3.Session().region_name or 'us-east-1'
DEFAULT_TF_REMOTE_CONFIG_BUCKET = 'terraform-state-{domain}'
DEFAULT_TF_REMOTE_CONFIG_KEY = 'terraform.tfstate'


def _mailgun_session(user, key):
    mailgun = requests.session()
    mailgun.auth = requests.auth.HTTPBasicAuth(user, key)
    return mailgun


def _get_routes(session):
    url = '{0}/routes'.format(MAILGUN)
    res = session.get(url)
    res.raise_for_status()
    return res.json()['items']


def _show_routes(args):
    mailgun = _mailgun_session(args.mailgun_user, args.mailgun_api_key)
    routes = _get_routes(mailgun)
    print(json.dumps(routes, sort_keys=True, indent=2))


def _create_route(args):
    """Create (or update existing) route."""
    mailgun = _mailgun_session(args.mailgun_user, args.mailgun_api_key)
    url = '{0}/routes'.format(MAILGUN)
    match_recipient = 'match_recipient("{recipient}@{domain}")'.format(
        recipient=args.recipient, domain=args.domain)
    data = [
        ('expression', match_recipient),
        ('description', args.description),
        ('priority', args.priority),
    ]
    # Add actions: you can pass multiple 'action' parameters
    data.extend([('action', 'forward("{0}")'.format(fv))
                 for fv in args.forward])

    if args.with_stop:
        # Simply stops the priority waterfall so the subsequent
        # routes will not be evaluated. Without a stop() action
        # executed, all lower priority Routes will also be evaluated.
        data.append(('action', 'stop()'))

    _data = {k: v for k, v in data if k != 'action'}
    _data['actions'] = [v for k, v in data if k == 'action']

    match_for_update = ('actions', 'expression')
    match_for_pass = match_for_update + ('priority', 'description')

    existing = _get_routes(mailgun)
    all_matched = next(
        (_route for _route in existing
         if all(_data[k] == _route[k] for k in match_for_pass)),
        None
    )
    if all_matched:
        print("Found existing matching route!", file=sys.stderr)
        print(json.dumps(all_matched, sort_keys=True, indent=2))
        return

    # if k2 set matches, just update (PUT) it
    updatable = next(
        (_route for _route in existing
         if all(_data[k] == _route[k] for k in match_for_update)),
        None
    )
    if updatable:
        url = '{0}/{id}'.format(url, id=updatable['id'])
        updated = mailgun.put(
            url,
            data=[item for item in data
                  if item[0] in ('description', 'priority')]
        )
        updated.raise_for_status()
        print(json.dumps(updated.json(), sort_keys=True, indent=2))
        return

    # Otherwise, create a brand new route!
    created = mailgun.post(url, data=data)
    created.raise_for_status()
    print(json.dumps(created.json(), sort_keys=True, indent=2))


def _show_domains(args):
    mailgun = _mailgun_session(args.mailgun_user, args.mailgun_api_key)
    url = '{0}/domains'.format(MAILGUN)
    res = mailgun.get(url)
    res.raise_for_status()
    if args.verbose:
        domains = res.json()['items']
    else:
        domains = [_x['name'] for _x in res.json()['items']]
    print(json.dumps(domains, sort_keys=True, indent=2))


def _show_domain(args):
    mailgun = _mailgun_session(args.mailgun_user, args.mailgun_api_key)
    url = '{0}/domains/{1}'.format(MAILGUN, args.domain)
    res = mailgun.get(url)
    res.raise_for_status()
    print(json.dumps(res.json(), sort_keys=True, indent=2))


def _tfvars(args):
    mailgun = _mailgun_session(args.mailgun_user, args.mailgun_api_key)
    url = '{0}/domains/{1}'.format(MAILGUN, args.domain)
    res = mailgun.get(url)
    res.raise_for_status()
    domain = res.json()
    tfv = collections.OrderedDict(
        sorted([
            ('domain', domain['domain']['name']),
            ('mailgun_smtp_password', domain['domain']['smtp_password']),
            ('mailgun_spam_action', domain['domain']['spam_action']),
            ('mailgun_wildcard', domain['domain']['wildcard']),
        ])
    )
    if args.with_api_key:
        tfv['mailgun_api_key'] = args.mailgun_api_key
    if args.print:
        print(json.dumps(tfv, sort_keys=True, indent=2))
    else:
        with open('terraform.tfvars.json', 'w') as tfvars_file:
            json.dump(tfv, tfvars_file, sort_keys=True, indent=2)


def _check_tf_config_bucket(bucket_name):
    s3_client = boto3.client('s3')
    try:
        s3_client.head_bucket(Bucket=bucket_name)
    except botocore.exceptions.ClientError as err:
        # 403 -> you can not haz, let this re-raise
        # 404 -> bucket doesn't exist
        if '404' in str(err):
            print('Creating bucket: {0}'.format(bucket_name), file=sys.stderr)
            bucket = boto3.resource('s3').create_bucket(Bucket=bucket_name)
            bucket.wait_until_exists()
        else:
            raise
    else:
        bucket = boto3.resource('s3').Bucket(bucket_name)

    bucket_vers = bucket.Versioning()
    # Let this throw an error if we aren't the owner.
    if bucket_vers.status != 'Enabled':
        print('Enabled bucket versioning for {0}'.format(
            bucket_name), file=sys.stderr)
        bucket_vers.enable()


def _tf_remote_config(args):
    # format remote config bucket value
    args.tf_remote_config_bucket = args.tf_remote_config_bucket.format(
        domain=args.domain.lower().replace('.', '-dot-'))
    if not args.dry_run:
        _check_tf_config_bucket(args.tf_remote_config_bucket)
    command = [
        'terraform', 'remote', 'config',
        '-state="{0}"'.format(args.tf_remote_config_key),
        # This doesn't seem to have an effect-- commenting out.
        # '-backup="{0}.backup"'.format(
        #     os.path.join(
        #         os.path.abspath(os.getcwd()),
        #         TERRAFORM_REMOTE_CONFIG_KEY
        #     )
        # ),
        '-backend="S3"',
        '-backend-config="bucket={0}"'.format(
            args.tf_remote_config_bucket
        ),
        '-backend-config="key={0}"'.format(args.tf_remote_config_key),
        '-backend-config="region={0}"'.format(args.aws_region),
        '-backend-config="encrypt=1"',
    ]
    command = ' '.join(command)
    if args.dry_run:
        print('Would run command:\n')
        print(command)
    else:
        subprocess.call(shlex.split(command))


def _dispatch(argumentparser):
    args = argumentparser.parse_args()
    required = ['mailgun_api_key', 'mailgun_user']
    for _arg in required:
        if hasattr(args, _arg) and not getattr(args, _arg, None):
            argumentparser.error('{0} required'.format(_arg))
    return args._func(args)


if __name__ == '__main__':

    parser = argparse.ArgumentParser(
        description='Terraform Mailgun AWS CLI.'
    )
    parser.add_argument(
        '--verbose', '-v',
        action='count',
    )
    parser.set_defaults(_func=lambda x: print('Try with --help'))

    def _mailgun_args(_parser):
        _parser.add_argument(
            '--mailgun-api-key', '-k',
            help='Defaults to the MAILGUN_API_KEY environment variable.',
            default=os.getenv('MAILGUN_API_KEY') or None,
        )
        _parser.add_argument(
            '--mailgun-user', '-u',
            help='Defaults to the MAILGUN_USER environment variable.',
            default=os.getenv('MAILGUN_USER') or 'api'
        )

    subparsers = parser.add_subparsers()
    # `main.py show-domains`
    show_domains = subparsers.add_parser(
        'show-domains',
        help='Show domains in Mailgun.'
    )
    _mailgun_args(show_domains)
    show_domains.set_defaults(_func=_show_domains)

    # `main.py show-domain`
    show_domain = subparsers.add_parser(
        'show-domain',
        help='Show details for a single Mailgun domain.'
    )
    _mailgun_args(show_domain)
    show_domain.add_argument(
        'domain',
        help='Show details for this domain.'
    )
    show_domain.set_defaults(_func=_show_domain)

    # `main.py create-route`
    create_route = subparsers.add_parser(
        'create-route',
        help=('Create a mailgun route. Checks for existing '
              'routes to prevent dupes. If a matching route exists, '
              'this command does nothing. If only "priority" or '
              '"description" changes, this will update the route '
              'attributes using the mailgun api (PUT), otherwise, '
              'a brand new route is created.')
    )
    _mailgun_args(create_route)
    create_route.add_argument(
        'domain',
        help='Create a route for mail sent to this domain.'
    )
    create_route.add_argument(
        '--recipient',
        default='.*',
        help=('Forward mails matching this recipient expression. '
              'Defaults to ".*" which matches ANY recipients on the '
              'domain.'),
    )
    # This is a nice combo: nargs=+, required, append.
    create_route.add_argument(
        '--forward', '-f',
        nargs='?',
        required=True,
        action='append',
        help=('Email address or location to forward email to. '
              'This argument may be specified multiple times to '
              'forward to multiple locations.')
    )
    create_route.add_argument(
        '--description', '-d',
        help='Route description',
        default=('Forward all mailgun domain email '
                 'to my specified forwarding location(s).')
    )
    create_route.add_argument(
        '--priority', '-p',
        type=int,
        # Setting this to 1 so that explicit recipient routes
        # can be added and triggered.
        default=1,
        help=('Rule priority, where 0 (zero) is highest priority'
              '(default: %(default)s)'),
    )
    create_route.add_argument(
        '--with-stop', '-s',
        action='store_true',
        default=False,
    )

    create_route.set_defaults(_func=_create_route)

    # `main.py show-routes`
    show_routes = subparsers.add_parser(
        'show-routes',
        help='Show routes for a single Mailgun domain.'
    )
    _mailgun_args(show_routes)
    show_routes.set_defaults(_func=_show_routes)

    # `main.py tfvars`
    tfvars = subparsers.add_parser(
        'tfvars',
        help=('Produce tfvars for infra setup and write them '
              '(unless --print is used) to terraform.tfvars.json '
              'which is picked up by terraform automatically.')
    )
    _mailgun_args(tfvars)
    tfvars.set_defaults(_func=_tfvars)
    tfvars.add_argument(
        'domain',
        help='Domain to get tfvars for.'
    )
    tfvars.add_argument(
        '--with-api-key',
        help='Add api key to tfvars output',
        action='store_true',
        default=False,
    )
    tfvars.add_argument(
        '--print',
        help='Just print the variables json; dont write to tfvars.json file',
        action='store_true',
        default=False,
    )

    # `main.py tf-remote-config`
    tf_remote_config = subparsers.add_parser(
        'tf-remote-config',
        help=('Configure the use of remote state '
              'storage in AWS S3 for terraform. This command '
              'also creates the S3 Bucket (if necessary) and ensures '
              'S3 Bucket versioning is enabled.'),
    )
    tf_remote_config.set_defaults(_func=_tf_remote_config)
    tf_remote_config.add_argument(
        'domain',
        help=('The domain is used to build the S3 bucket name. '
              'e.g. FOO.com results in a bucket named '
              'terraform-state-foo-dot-com.')
    )
    tf_remote_config.add_argument(
        '--dry-run', '-d',
        action='store_true',
        default=False,
        help=("Don't run the terraform remote config command, "
              "just show me the command.")
    )
    tf_remote_config.add_argument(
        '--tf-remote-config-bucket',
        default=DEFAULT_TF_REMOTE_CONFIG_BUCKET,
        help=('S3 bucket to use for terraform remote state'
              '(default: %(default)s)'),
    )
    tf_remote_config.add_argument(
        '--tf-remote-config-key',
        default=DEFAULT_TF_REMOTE_CONFIG_KEY,
        help=('S3 key to use for terraform remote state file'
              '(default: %(default)s)'),
    )
    tf_remote_config.add_argument(
        '--aws-region', '-r',
        default=AWS_DEFAULT_REGION,
        help=('AWS Region for terraform S3 backend. '
              'The standard aws/boto machinery will look this up in your '
              'environment, else falls back to us-east-1. '
              '(default: %(default)s)'),
    )

    try:
        # Parse argument and check required.
        _dispatch(parser)
    except KeyboardInterrupt:
        print(' Stahp', file=sys.stderr)
        sys.exit(1)
