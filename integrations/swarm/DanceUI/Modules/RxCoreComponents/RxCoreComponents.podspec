Pod::Spec.new do |s|
  s.name         = 'RxCoreComponents'
  s.version      = '1.0.0'
  s.summary      = 'RxCoreComponents binary distribution'
  s.homepage     = 'https://github.com/nicklockwood/RxCoreComponents'
  s.license      = { :type => 'Proprietary' }
  s.author       = { 'ByteDance' => 'aspect-oriented-design@bytedance.com' }
  s.source       = { :path => '.' }
  s.ios.deployment_target = '13.0'

  s.vendored_frameworks = 'lib/RxCoreComponents.xcframework'
  s.source_files = 'include/**/*.h'
  s.public_header_files = 'include/**/*.h'
  s.header_dir = 'RxCoreComponents'

  s.dependency 'RxFoundation'
end
