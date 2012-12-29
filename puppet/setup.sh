#!/bin/bash

# This script ensures that Ruby and Puppet installed on the server.
# only tested under Ubuntu 10.04 and 12.04.

apt-get update
apt-get ruby
apt-get rubygems
apt-get install libopenssl-ruby    # Ubuntu 10.04 requires it

# maybe got some errors about RDoc here, but doesn't matter
gem install puppet

# puppet should be run now, make sure 'puppet' group and user exist.
puppet resource group puppet ensure=present
puppet resource user puppet ensure=present gid=puppet shell='/sbin/nologin'

# set gem executable PATH for Ubuntu 10.04
if grep -q '10.04' /etc/issue ; then
    cat > /etc/profile.d/gem.sh <<'EOF'
PATH=$PATH:/var/lib/gems/1.8/bin
EOF
fi

# give a try
puppet apply <<EOF
file {'/tmp/hello-puppet.txt':
  ensure => present,
  content => "Hello, Puppet!\n",
}
EOF
