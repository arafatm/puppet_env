class profiles::database_services {

  $db_hash     = hiera_hash('profiles::database_services::db_hash')
  $db_defaults = hiera('profiles::database_services::db_defaults')

  case $::kernel {
    'linux': {
      require mysql::server
      class {'mysql::bindings':
        php_enable => true,
      }

      # create databases
      create_resources('mysql::db',$db_hash,$db_defaults)

      # firewall rules
      firewall { '101 allow mysql access':
        port   => [3306],
        proto  => tcp,
        action => accept,
      }
    }
    'windows': {

      #create service
      sqlserver_instance{'MSSQLSERVER':
          features                => ['SQL'],
          source                  => 'E:/',
          sql_sysadmin_accounts   => ['dbuser'],
      }
      sqlserver_features { 'Generic Features':
        source    => 'E:/',
        features  => ['ADV_SSMS', 'BC', 'Conn', 'SDK', 'SSMS'],
      }

      $db_hash.each |$key, $value| {
        sqlserver::database { $key:
          instance => 'MSSQLSERVER',
        }
        sqlserver::login{ "${key}_login":
            password => 'Pupp3t1@',
        }

        sqlserver::user{ "${key}_user":
            user     => "${key}_user",
            database => $key,
            require  => Sqlserver::Login["${key}_login"],
        }
      }
    }
    default: {
      fail("${::kernel} is not a support OS kernel")
    }
  }
}
