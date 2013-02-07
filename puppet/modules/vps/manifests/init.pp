# = Class: vps
#
# This class is a dummy one.
#
# == Parameters:
#
# $enable::  Whether to play the function. Defaults to true.
#            Valid alues: true and false.
#
# == Requires:
#
# Nothing.
#
# == Sample Usage:
#
#   class { 'vps': }
#
#   include vps
#
class vps ($enable = true) {
  $file_name = '/tmp/puppet-module-vps.txt'
  if $enable == true {
    file { $file_name:
      ensure  => present,
      content => "This module works!\n",
    }
  }
  else {
    file { $file_name:
      ensure  => absent,
    }
  }
}
