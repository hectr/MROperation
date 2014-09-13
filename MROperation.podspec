Pod::Spec.new do |s|
  s.name     = 'MROperation'
  s.version  = '0.0.1'
  s.license  = { :type => 'MIT', :file => 'LICENSE' }
  s.summary  = 'NSOperation subclass that manages the concurrent execution of a block.'
  s.homepage = 'https://github.com/hectr/MROperation'
  s.authors  = { 'Héctor Marqués Ranea' => 'h@mrhector.me' }
  s.source   = { :git => 'https://github.com/hectr/MROperation.git', :commit => s.version.to_s }
  s.source_files = 'MROperation'
  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'
  s.requires_arc = true
end
