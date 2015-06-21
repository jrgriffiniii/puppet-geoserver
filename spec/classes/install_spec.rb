require 'spec_helper'

describe 'geoserver::install' do

  context 'on CentOS 6.4' do

    let :facts do
      {
        :osfamily => 'RedHat',
        :operatingsystem => 'CentOS',
        :operatingsystemrelease => '6.4',
        :concat_basedir => '/var/lib/puppet'
      }
    end

    # Checking for Puppet syntax errors
 #   it { should compile }

    it { should contain_class('geoserver::install') }

    # Ensure that the Puppet Module dependencies are loaded
    it { should contain_class('java') }
    it { should contain_class('epel') }
    it { should contain_class('tomcat') }
    it { should contain_class('postgresql::globals') }
    it { should contain_class('postgresql::server') }

    # Ensure that the Tomcat server instance is created
    it {

      should contain_tomcat__instance('default')
        .with_package_name('tomcat')
    }

    # Ensure that the Tomcat service is running
    it {

      should contain_tomcat__service('default')
        .with_use_jsvc(false)
        .with_use_init(true)
        .with_service_name('tomcat')
    }

    # Ensure that the proper system packages are installed
    it { should contain_package('unzip') }

    # Firewall rules
    it { should(contain_firewall('001 allow http and https access for the Java Servlet Engine')
                  .with_port([8080, 8443])) }

    # Ensure the the PostgreSQL server is created
    it { should contain_class('postgresql::server')
        .with_listen_addresses("*") }

    # Ensure that the PostGIS database is created
    it {

      should contain_postgresql__server__database('template_postgis')
        .with_istemplate(true)
        .with_template('template1')
    }

    # Ensure that the PostGIS pg/psql extension is installed
    it { should contain_exec('createlang plpgsql template_postgis')
        .with_user('postgres')
        .that_requires('Postgresql::Server::Database[template_postgis]')
    }

    # /usr/pgsql-${::postgresql::globals::globals_version}/share/contrib/postgis-${::postgresql::globals::globals_postgis_version}

    # Ensure that the base PostGIS template is installed

    # Ensure that the spatial reference system template is installed
    it { should contain_exec('psql -q -d template_postgis -f /usr/pgsql-8.4/share/contrib/postgis-1.5/postgis.sql')
        .with_user('postgres')
    }

    it { should contain_exec('psql -q -d template_postgis -f /usr/pgsql-8.4/share/contrib/postgis-1.5/spatial_ref_sys.sql')
        .with_user('postgres')
    }

    # Ensure that the role is added
    describe 'postgresql::server::role' do

      it { should contain_postgresql__server__role('geoserver') }
    end

    # Ensure that the database is created
    describe 'Postgresql::Server::Db' do

      it { should contain_postgresql__server__db('geoserver') }
    end

    # GeoServer

    it { should contain_exec('download_geoserver') }
    it { should contain_exec('deploy_geoserver') }

  end
end
