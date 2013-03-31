#!/bin/bash
# let's assume CWD is the code checkout
sudo apt-get update
sudo apt-get install -y git ruby1.9.1 build-essential ruby1.9.1-dev libxml2-dev libxslt-dev libsqlite3-dev lvm2 xfsprogs
sudo gem install bundler --no-user --no-rdoc --no-ri
bundle install --standalone

fpm --post-install `pwd`/post-install -s dir -t deb -n ebssense -v $EBSSENSE_VERSION -C $BUILD_ROOT -p $DEBNAME -d dependency -d dependency -d dependency -d dependency srv etc

