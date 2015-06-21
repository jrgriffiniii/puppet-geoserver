# == Class: geoserver::install
#
# Class for managing the installation process of GeoServer
#
class geoserver::install inherits geoserver {

  package { "unzip":

    ensure => "installed"
  }

  class { '::java': }

  # Apache Tomcat
  class { 'epel': } ->
  class { '::tomcat':
    
    install_from_source => false,
  } ->
  tomcat::instance { 'default':
    
    package_name  => 'tomcat',
    } ->
  firewall { '001 allow http and https access for the Java Servlet Engine':
    
    port   => [8080, 8443],
    proto  => tcp,
    action => accept,
    } ->
  tomcat::service { 'default':
    
    use_jsvc     => false,
    use_init     => true,
    service_name => 'tomcat',
  }

  # PostgreSQL for GeoServer
  class { 'postgresql::globals':
    
    manage_package_repo => true,
    } ->
  class { 'postgresql::server':
      
    listen_addresses => '*',

    # ip_mask_deny_postgres_user => '0.0.0.0/32',
    # ip_mask_allow_all_users    => '0.0.0.0/0',
    # ipv4acls                   => ['hostssl all 192.168.0.0/24 cert'],
    postgres_password          => 'secret',
  }

  # PostGIS for the GeoServer database
  # include ::postgis

  # The following error is encountered for CentOS 6.4:
  # Error: psql -q -d template_postgis -f /usr/pgsql-8.4}/share/contrib/postgis-1.5/postgis.sql returned 1 instead of one of [0]

  # A proposed modification has been made using pull request 33: https://github.com/camptocamp/puppet-postgis/pull/33
  # @todo Remove this work-around

  class { 'postgresql::server::postgis': }
  ->
  postgresql::server::database { 'template_postgis':
    
    istemplate => true,
    template => 'template1',
  }

  $script_path = "/usr/pgsql-${::postgresql::globals::globals_version}/share/contrib/postgis-${::postgresql::globals::globals_postgis_version}"
  
  Exec {
    
    path => ['/usr/bin', '/bin', ],
  }
  exec { 'createlang plpgsql template_postgis':
    
    user => 'postgres',
    unless => 'createlang -l template_postgis | grep -q plpgsql',
    require => Postgresql::Server::Database['template_postgis'],
    } ->
  exec { "psql -q -d template_postgis -f ${script_path}/postgis.sql":
    user => 'postgres',
    unless => 'echo "\dt" | psql -d template_postgis | grep -q geometry_columns',
    } ->
  exec { "psql -q -d template_postgis -f ${script_path}/spatial_ref_sys.sql":
    user => 'postgres',
    unless => 'test $(psql -At -d template_postgis -c "select count(*) from spatial_ref_sys") -ne 0',
  }

  postgresql::server::role { 'geoserver':
    
    password_hash => postgresql_password('geoserver', 'secret')
  }

  postgresql::server::db { 'geoserver':
    
    user     => 'geoserver',
    password => postgresql_password('geoserver', 'secret')
  }

  $install_destination = '/var/lib/tomcat/webapps' # @todo Resolve why ::tomcat::catalina_home does not resolve to /var/lib/tomcat

  # http://sourceforge.net/projects/geoserver/files/GeoServer/2.6.1/geoserver-2.6.1-war.zip  
  exec { "download_geoserver" :
    
    command => "/usr/bin/wget http://sourceforge.net/projects/geoserver/files/GeoServer/2.6.1/geoserver-2.6.1-war.zip -O /tmp/geoserver.zip",
    creates => "/tmp/geoserver.zip",
    require => Package['unzip']
    } ->

  exec { "deploy_geoserver" :
    
    command => "/usr/bin/unzip /tmp/geoserver.zip geoserver.war -d ${install_destination}",
    creates => "${install_destination}/geoserver.war",
    require => Tomcat::Instance['default']
  }


  # docroot must be set for the reverse proxy?
  # @todo Resolve
  
#  class {'::apache': }

#  apache::vhost { 'localhost.localdomain':
    
#    port     => '443',
    # docroot  => '/var/www/fourth',
#    ssl      => true,
#    ssl_cert => '/etc/ssl/localhost.localdomain.cert',
#    ssl_key  => '/etc/ssl/localhost.localdomain.key'
#  }
}
