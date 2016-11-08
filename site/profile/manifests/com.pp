class profile::com {

  $manage_hiera   = hiera('profile::com::manage_hiera', true)
  $hiera_backends = hiera_hash('profile::com::hiera_backends', undef)
  $hiera_hierarchy = hiera_array('profile::com::hiera_hierarchy', undef)

  Firewall {
    before  => Class['profile::fw::post'],
    require => Class['profile::fw::pre'],
  }

  Pe_ini_setting {
    path    => $::settings::config,
    section => 'main',
    notify  => Service['pe-puppetserver'],
  }

  firewall { '100 allow puppet access':
    dport  => [8140],
    proto  => tcp,
    action => accept,
  }

  firewall { '100 allow mco access':
    dport  => [61613],
    proto  => tcp,
    action => accept,
  }

  firewall { '100 allow amq access':
    dport  => [61616],
    proto  => tcp,
    action => accept,
  }

  pe_ini_setting { 'pe_user':
    ensure  => present,
    setting => 'user',
    value   => 'pe-puppet',
  }

  pe_ini_setting { 'pe_group':
    ensure  => present,
    setting => 'group',
    value   => 'pe-puppet',
  }

  if $manage_hiera and (! $hiera_backends or ! $hiera_hierarchy) {
    fail('The hash `hiera_backends` and array `hiera_hierarchy` must exist when managing hiera')
  }

  @@haproxy::balancermember { "master00-${::fqdn}":
    listening_service => 'puppet00',
    server_names      => $::fqdn,
    ipaddresses       => $::ipaddress_eth1,
    ports             => '8140',
    options           => 'check',
  }
  @@haproxy::balancermember { "mco00-${::fqdn}":
    listening_service => 'mco00',
    server_names      => $::fqdn,
    ipaddresses       => $::ipaddress_eth1,
    ports             => '61613',
    options           => 'check',
  }

  if $manage_hiera {
    package { 'hiera-eyaml':
      ensure   => present,
      provider => 'puppetserver_gem',
      before   => File['/etc/puppetlabs/puppet/hiera.yaml'],
    }

    file { '/etc/puppetlabs/puppet/ssl/private_key.pkcs7.pem':
      ensure  => file,
      owner   => 'pe-puppet',
      group   => 'pe-puppet',
      mode    => '0600',
      content => file('/etc/puppetlabs/puppet/ssl/private_key.pkcs7.pem'),
      before   => File['/etc/puppetlabs/puppet/hiera.yaml'],
    }

    file { '/etc/puppetlabs/puppet/ssl/public_key.pkcs7.pem':
      ensure  => file,
      owner   => 'pe-puppet',
      group   => 'pe-puppet',
      mode    => '0644',
      content => file('/etc/puppetlabs/puppet/ssl/public_key.pkcs7.pem'),
      before   => File['/etc/puppetlabs/puppet/hiera.yaml'],
    }

    file { '/etc/puppetlabs/puppet/hiera.yaml':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('profile/hiera.yaml.erb'),
      notify  => Service['pe-puppetserver'],
    }
  }

  @@puppet_certificate { "${::fqdn}-peadmin":
    ensure => present,
    tag    => 'mco_clients',
  }

  puppet_enterprise::mcollective::client { "${::fqdn}-peadmin":
    activemq_brokers => [$::clientcert],
    logfile          => "/var/lib/${::fqdn}-peadmin/${::fqdn}-peadmin.log",
    create_user      => true,
  }

}
