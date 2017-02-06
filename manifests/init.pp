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

class htcondor ( $type = 'compute', $net_interface = 'eth0') {
  
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
      $condor_conf = @("END")
        RELEASE_DIR = /usr

	LOCAL_DIR = /var

	LOCAL_CONFIG_FILE = /etc/condor/condor_config.local
	REQUIRE_LOCAL_CONFIG_FILE = false

	LOCAL_CONFIG_DIR = /etc/condor/config.d

	ALLOW_READ            = *
	ALLOW_WRITE           = *
	ALLOW_ADMINISTRATOR   = *
	ALLOW_CONFIG          = *
	ALLOW_NEGOTIATOR      = *
	ALLOW_DAEMON          = *

	HOSTALLOW_READ = 
	HOSTALLOW_WRITE = 
	HOSTALLOW_DAEMON = 
	HOSTALLOW_NEGOTIATOR = 
	HOSTALLOW_ADMINISTRATOR = 
	HOSTALLOW_OWNER = 

	BIND_ALL_INTERFACES = False
	NETWORK_INTERFACE = $net_interface

	RUN     = $(LOCAL_DIR)/run/condor
	LOG     = $(LOCAL_DIR)/log/condor
	LOCK    = $(LOCAL_DIR)/lock/condor
	SPOOL   = $(LOCAL_DIR)/lib/condor/spool
	EXECUTE = $(LOCAL_DIR)/lib/condor/execute
	BIN     = $(RELEASE_DIR)/bin
	LIB     = $(RELEASE_DIR)/lib/condor
	INCLUDE = $(RELEASE_DIR)/include/condor
	SBIN    = $(RELEASE_DIR)/sbin
	LIBEXEC = $(RELEASE_DIR)/lib/condor/libexec
	SHARE   = $(RELEASE_DIR)/share/condor

	PROCD_ADDRESS = $(RUN)/procd_pipe

	CONDOR_HOST = 10.0.72.94
	COLLECTOR_HOST = $(CONDOR_HOST):4080?sock=collector
	SCHEDD_HOST = $(CONDOR_HOST)

	SLOT_TYPE_1 = cpus=100%,disk=100%,swap=100%
	SLOT_TYPE_1_PARTITIONABLE = True

	NUM_SLOTS_TYPE_1 = 1

	DAEMON_LIST = MASTER,STARTD

	LOWPORT = 5000
	HIGHPORT = 6000

	DOCKER = /usr/bin/docker
	| END
      content => $condor_conf,
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
