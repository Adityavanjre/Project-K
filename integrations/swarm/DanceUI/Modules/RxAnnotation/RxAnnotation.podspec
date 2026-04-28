Pod::Spec.new do |s|
  s.name         = 'RxAnnotation'
  s.version      = '1.0.0'
  s.summary      = 'RxAnnotation binary distribution'
  s.homepage     = 'https://github.com/nicklockwood/RxAnnotation'
  s.license      = { :type => 'Proprietary' }
  s.author       = { 'ByteDance' => 'aspect-oriented-design@bytedance.com' }
  s.source       = { :path => '.' }
  s.ios.deployment_target = '13.0'

  s.vendored_frameworks = 'lib/RxAnnotation.xcframework'
  s.source_files = 'include/**/*.h'
  s.public_header_files = 'include/**/*.h'
  s.header_dir = 'RxAnnotation'
end
