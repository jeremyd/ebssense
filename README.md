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

    ebssense --help

# Usage

Ebssense has descriptions of each option when you specify --help on any of the sub-commands.

### Setup the standard environment variables for AWS Credentials

    export AWS_SECRET_KEY=XXX
    export AWS_ACCESS_KEY=XXX

### Creating a fresh volume-stripe from scratch.

    ebssense build --help
    Options:
                --name, -n <s>:   Unique name to be used for all operations regarding this data set.
             --num-vol, -u <i>:   Number of EBS volumes to stripe together with LVM.
            --size-vol, -s <i>:   Size of *each EBS volume in Gigabytes
         --mount-point, -m <s>:   Mount point where the LVM stripe will be mounted. (Default: /mnt/ebs)
     --device-letters, -d <s+>:   Choose the device name suffix(s) for all volumes in the stripe.  Use one letter per volume separated by spaces.  Example --device-letters l m n o p --num-vol 5
     --lvm-device-name, -l <s>:   LVM device name. (Default: lvol1)
    --lvm-volume-group, -v <s>:   LVM volume group name. (Default: esense-vg-data)
              --region, -r <s>:   Amazon EC2 region. (Default: us-east-1)

### Backing up the volume stripe.

    ebssense backup --name <id>

### Automatic expiration of old backups.

    ebssense clean --name <id> --keep <backups to keep>

### Listing metadata.

    ebssense list

    ebssense list --name <id>

### Restoring the volume stripe from backup.

Optional: show all found tags in the account.

    ebssense list --tags

Synchronize locally the metadata for the sets tagged with id.

    ebssense list --sync <id> 

Restore.

    ebssense restore --name <id>
