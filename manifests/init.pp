# This module is for setting up iPlant UK's HTCondor cluster
# It assumes all nodes in the cluster are running Ubuntu (or something else Debian based)
#
# Three classes of nodes are possible:
#   - master, which keeps track of the cluster
#   - submit, which runs the schedd and negotiator daemons responsible for submitting jobs
#   - compute, which are worker nodes
# see the conf files in this module's files dir for HTCondor setup details for all three classes.
# 
# example call in site.pp for a master node:
# node 'masterofpuppets'{
#   class {'htcondor':
#     type => 'master'
#   }
# }
#
# default $type is 'compute'

class htcondor ( $type = 'compute') {
  
  # Add the htcondor repo and key, so we can install via apt
  apt::source { 'htcondor_repo':
    before   => Package['condor'],
    comment  => 'HTCondor debian repo',
    location => 'http://research.cs.wisc.edu/htcondor/debian/stable/',
    release  => 'wheezy',
    repos    => 'contrib',
    key      => {
      id       => '4B9D355DF3674E0E272D2E0A973FC7D2670079F6',
      source   => 'http://research.cs.wisc.edu/htcondor/debian/HTCondor-Release.gpg.key',
    }
  }
  
  # Install with apt
  package { 'condor':
    before => File['/etc/condor/condor_config'],
    require => Exec[apt_update],
    ensure  => 'installed',
  }

  # Add the correct condor config file and restart daemons
  # COMPUTE
  if $type == 'compute' {
    service { 'condor':
      ensure  => running,
    }
    file { '/etc/condor/condor_config':
      ensure => present,
      source => "puppet:///modules/htcondor/conf/condor_${type}_conf",
      notify => Service['condor'],
    }
  } 

  # SUBMIT
  if $type == 'submit' {
    service { 'condor':
      ensure  => running,
    }
    file { '/etc/condor/condor_config':
      ensure => present,
      source => "puppet:///modules/htcondor/conf/condor_${type}_conf",
      notify => Service['condor'],
    }
  } 

  # MASTER
  if $type == 'master' {
    service { 'condor':
      require => Package['condor'],
      ensure  => running,
    }
    file { '/etc/condor/condor_config':
      ensure => present,
      source => "puppet:///modules/htcondor/conf/condor_${type}_conf",
      notify => Service['condor'],
    }
  }
}
