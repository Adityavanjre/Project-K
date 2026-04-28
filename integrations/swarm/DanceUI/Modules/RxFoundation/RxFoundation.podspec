Pod::Spec.new do |s|
  s.name         = 'RxFoundation'
  s.version      = '1.0.0'
  s.summary      = 'RxFoundation binary distribution'
  s.homepage     = 'https://github.com/nicklockwood/RxFoundation'
  s.license      = { :type => 'Proprietary' }
  s.author       = { 'ByteDance' => 'aspect-oriented-design@bytedance.com' }
  s.source       = { :path => '.' }
  s.ios.deployment_target = '13.0'

  s.vendored_frameworks = 'lib/RxFoundation.xcframework'
  s.source_files = 'include/**/*.{h,hpp}'
  s.public_header_files = 'include/**/*.{h,hpp}'
  s.header_dir = 'RxFoundation'
  s.libraries = 'c++'
  s.pod_target_xcconfig = { 'CLANG_CXX_LANGUAGE_STANDARD' => 'c++14' }
end
