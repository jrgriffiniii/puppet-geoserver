# == Class: geoserver
#
# Parameters for the geoserver Class
#
class geoserver::params {

  $download_url = 'http://sourceforge.net/projects/geoserver/files/GeoServer/2.6.1/geoserver-2.6.1-war.zip'
  $version = '2.6.1'

  # Define $CATALINA_HOME
  $servlet_home = '/usr/share/tomcat'
  $servlet_http_port = 8080
  $servlet_https_port = 8443
  
  $home = '/usr/local/fedora'
  $users = "${home}/server/config/fedora-users.xml"

  $servlet_engine = 'tomcat'
  $servlet_engine_package = 'tomcat'
  $servlet_webapps_dir_path = '/var/lib/tomcat/webapps'
  $servlet_context_dir_path = '/etc/tomcat/Catalina/localhost'
  $servlet_host = 'localhost'
  $servlet_port = '8080'
  $servlet_user = 'tomcat'
  $servlet_group = 'tomcat'
}
