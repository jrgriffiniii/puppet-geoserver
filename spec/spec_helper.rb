require 'rspec-puppet'

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

RSpec.configure do |c|
  c.module_path = 'modules'
  c.manifest_dir = 'manifests'

  c.module_path = File.join(fixture_path, 'modules')
  c.manifest_dir = File.join(fixture_path, 'manifests')

  c.manifest = 'manifests/default.pp'
end

at_exit { RSpec::Puppet::Coverage.report! }
