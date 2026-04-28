# frozen_string_literal: true

require_relative './Scripts/pod_env'

Pod::Spec.new do |s|
  s.name = 'DanceUIComposeModule'
  s.version = DanceUI::PodEnv.version
  s.summary = 'DSL'

  s.description = <<-DESC
    TODO: Add long description of the pod here.
  DESC

  s.homepage = 'https://github.com/retval/DanceUI'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license = { type: 'MIT', file: 'LICENSE' }
  s.author = { 'retval' => 'retval@me.com' }
  s.source = { git: '', branch: 'release_' + s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  
  s.ios.deployment_target = DanceUI::PodEnv.danceuiApp_deployment_target

  s.source_files = 'Sources/**/*.{h,c,m,mm,swift}'
  
  s.public_header_files = 'Sources/**/*.h'
  
  s.requires_arc = true

  s.dependency 'DanceUI'
  s.dependency 'DanceUICompose'
  s.dependency 'RxInjector/Annotation'

end
