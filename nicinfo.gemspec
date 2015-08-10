lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'nicinfo/constants'

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
