
Pod::Spec.new do |s|
  s.name        = 'MROperation'
  s.version     = '0.1.0'
  s.summary     = 'NSOperation subclass that manages the concurrent execution of a block.'
  s.description      = <<-DESC
                       The `MROperation` class is a concrete subclass of `NSOperation` that manages the concurrent execution of a block.
                       DESC
  s.homepage         = 'https://github.com/hectr/MROperation'
  s.license          = 'MIT'
  s.author           = { "hectr" => "h@mrhector.me" }
  s.source           = { :git => 'https://github.com/hectr/MROperation.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/hectormarquesra'

  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'
  s.requires_arc          = true

  s.source_files = 'MROperation'
end
