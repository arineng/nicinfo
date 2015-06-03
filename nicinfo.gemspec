$LOAD_PATH << File.join( File.dirname( File.expand_path(__FILE__ ) ), 'lib' )

require 'constants'

Gem::Specification.new do |s|
  s.name        = 'nicinfo'
  s.version     = NicInfo::VERSION
  s.date        = '2015-06-03'
  s.summary     = "RDAP Client"
  s.description = "A command-line RDAP client."
  s.authors     = ["Andrew Newton"]
  s.email       = 'andy@arin.net'
  s.files       = Dir["lib/**/*"].entries
  s.homepage    =
          'https://github.com/arinlabs/nicinfo'
  s.license       = 'ISC'
  s.executables << 'nicinfo'
end