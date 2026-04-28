# frozen_string_literal: true

require './Scripts/pod_env'

Pod::Spec.new do |s|
  s.name             = 'DanceUIObservationMacro'
  s.version          = DanceUI::PodEnv.version
  s.summary          = 'DanceUIObservation Swift Macro'
  s.description      = <<-DESC
                       Swift Observation Macro compiler plugin by the DanceUI team.
                       DESC
  s.homepage         = 'https://github.com/ByteDance/DanceUI'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Li Yu-long' => 'liyulong.manfred@bytedance.com' }
  s.source           = {
    :git => '',
    :branch => 'release_' + s.version.to_s
  }

  s.ios.deployment_target = DanceUI::PodEnv.danceuiApp_deployment_target

  # Empty source files - this pod only provides the pre-built macro binary
  s.source_files = 'Sources/DanceUIObservationMacro/**/*.swift'

  s.prepare_command = <<-CMD
    set -e
    echo "Building DanceUIObservationMacroImpl..."
    swift build -c release --product DanceUIObservationMacroImpl --disable-sandbox
    mkdir -p .product
    BIN_PATH=$(swift build -c release --product DanceUIObservationMacroImpl --show-bin-path --disable-sandbox)
    # The binary may be named with -tool suffix
    if [ -f "$BIN_PATH/DanceUIObservationMacroImpl" ]; then
      cp "$BIN_PATH/DanceUIObservationMacroImpl" .product/
    elif [ -f "$BIN_PATH/DanceUIObservationMacroImpl-tool" ]; then
      cp "$BIN_PATH/DanceUIObservationMacroImpl-tool" .product/DanceUIObservationMacroImpl
    else
      echo "Error: Could not find DanceUIObservationMacroImpl binary"
      ls -la "$BIN_PATH/"
      exit 1
    fi
    echo "DanceUIObservationMacroImpl built successfully"
  CMD

  s.swift_version = '5.9'
  s.static_framework = true
end
