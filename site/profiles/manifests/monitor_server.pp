class monitor_server {

  if $::osfamily != 'redhat' {
    fail("This class is only for EL family")
  }

  require epel
  include apache
  ensure_packages('nagios')

  file { '/etc/httpd/conf.d/nagios.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profiles/nagios.conf.erb'),
    require => Package['nagios'],
  }

  service { 'nagios':
    ensure    => running,
    subscribe => File['/etc/httpd/conf.d/nagios.conf'],
  }

  Nagios_host <<||>>
  Nagios_service <<||>>

}
