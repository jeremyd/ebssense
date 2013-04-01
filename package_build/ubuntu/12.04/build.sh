#!/bin/bash -e
# let's assume CWD is the code checkout
EBSSENSE_VERSION=0.0.1
DEBNAME=ebssense
BUILDROOT=tmp/build_root

mkdir -p tmp/build_root

sudo apt-get update
sudo apt-get install -y git ruby1.9.1 build-essential ruby1.9.1-dev libxml2-dev libxslt-dev libsqlite3-dev lvm2 xfsprogs
sudo gem install bundler --no-user --no-rdoc --no-ri
bundle install --standalone

rsync -rv lib/ $BUILDROOT/var/lib/clustersense/lib
rsync -rv bin/ $BUILDROOT/var/lib/clustersense/bin
rsync -rv bundle/ $BUILDROOT/var/lib/clustersense/bundle
rsync -rv .bundle/ $BUILDROOT/var/lib/clustersense/.bundle
rsync -rv spec/ $BUILDROOT/var/lib/clustersense/spec

sudo gem install fpm --no-user --no-rdoc --no-ri

#fpm --post-install `pwd`/post-install -s dir -t deb -n ebssense -v $EBSSENSE_VERSION -C $BUILD_ROOT -p $DEBNAME -d dependency -d dependency -d dependency -d dependency srv etc

fpm -s dir -t deb -n ebssense -v $EBSSENSE_VERSION -C $BUILDROOT -p $DEBNAME -d lvm2 -d xfsprogs -d ruby1.9.1 -d libxml2 -d libxslt var
