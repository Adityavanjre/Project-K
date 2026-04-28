# frozen_string_literal: true

require './Scripts/pod_env'

Pod::Spec.new do |s|
  s.name             = 'DanceUIObservation'
  s.version          = DanceUI::PodEnv.version
  s.summary          = 'DanceUIObservation'
  s.description      = <<-DESC
                       Swift Observation by the DanceUI team.
                       DESC
  s.homepage         = 'https://github.com/ByteDance/DanceUI'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Li Yu-long' => 'liyulong.manfred@bytedance.com' }
  s.source           = {
    :git => '',
    :branch => 'release_' + s.version.to_s
  }

  s.ios.deployment_target = DanceUI::PodEnv.danceuiApp_deployment_target

  s.source_files = [
    'Sources/DanceUIObservation/*.swift',
  ]

  s.dependency 'DanceUIObservationMacro'

  s.pod_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => [
      "-no-verify-emitted-module-interface",
    ],
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'NO',
    'BUILD_LIBRARY_FOR_DISTRIBUTION_ReleaseBits' => 'YES',
  }

  s.user_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => [
      '-load-plugin-executable',
      "${PODS_ROOT}/../../Modules/DanceUIObservation/.product/DanceUIObservationMacroImpl#DanceUIObservationMacroImpl",
    ],
  }

  s.swift_version = '5.9'
  s.static_framework = true
end
