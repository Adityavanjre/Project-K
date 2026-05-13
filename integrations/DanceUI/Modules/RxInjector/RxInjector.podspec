Pod::Spec.new do |s|
  s.name         = 'RxInjector'
  s.version      = '1.0.0'
  s.summary      = 'RxInjector binary distribution'
  s.homepage     = 'https://github.com/nicklockwood/RxInjector'
  s.license      = { :type => 'Proprietary' }
  s.author       = { 'ByteDance' => 'aspect-oriented-design@bytedance.com' }
  s.source       = { :path => '.' }
  s.ios.deployment_target = '13.0'

  s.vendored_frameworks = 'lib/RxInjector.xcframework'
  s.source_files = 'include/**/*.h'
  s.public_header_files = 'include/**/*.h'
  s.header_dir = 'RxInjector'

  s.dependency 'RxAnnotation'
  s.dependency 'RxFoundation'
  s.dependency 'RxCoreComponents'

  # Subspec for backward compatibility with 'RxInjector/Annotation'
  s.subspec 'Annotation' do |ss|
    ss.source_files = 'include/**/*.h'
    ss.public_header_files = 'include/**/*.h'
    ss.vendored_frameworks = 'lib/RxInjector.xcframework'
    ss.dependency 'RxAnnotation'
    ss.dependency 'RxFoundation'
    ss.dependency 'RxCoreComponents'
  end
end
