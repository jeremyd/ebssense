# Thank you for flying Ebssense!

# What is it?

Ebssense is an opensource command-line tool for managing high-performance EBS volume stripes and making backups of them using EBS snapshot sets.

# Why would I use it?

LVM stripe across multiple EBS volumes is higher performance than a single volume.

LVM snapshots enable very small backup windows and the transfer of the backup happens via a background EBS snapshot.

EC2 tagging of volumes and snapshots makes for easy management via the AWS console and no lock-in to this tool.

Local SQlite caching of tagged metadata makes operations very quick and not 100% reliant on doing tag lookups.

# Quickstart

## Install from packages

#### Ubuntu 12.04 Package

    wget https://s3-us-west-1.amazonaws.com/ebssense/ebssense_0.0.1-20.deb
    dpkg -i ebssense_0.0.1-20.deb
    apt-get -f install
    ebssense build --help

#### Debian Package (coming soon)
#### Archlinux Package (coming soon)

## Install from source

### Install the pre-requirements from system packages:

- Ruby >= 1.9 with bundler >= 1.3
- lvm2
- xfsprogs
- libxml2
- libxslt

### Build

    git clone git://github.com/jeremyd/ebssense
    cd ebssense
    gem install bundler
    bundle install --standalone

Now you can run the tool directly from the checkout location's bin dir:

    bin/ebssense --help

# Usage

Ebssense has extensive descriptions of each options available by using the --help flag on any of the sub-commands.

### Setup the standard environment variables for AWS Credentials

    export AWS_SECRET_KEY=XXX
    export AWS_ACCESS_KEY=XXX

### Creating a fresh volume-stripe from scratch.

    bin/ebssense build --help

### Backing up the volume stripe.

    bin/ebssense backup --help

### Restoring the volume stripe from backup.

    bin/ebssense list --sync <myName>
    bin/ebssense restore --help
