# frozen_string_literal: true

require_relative './Scripts/pod_env'

# "danceui_use_dynamic" is an global environment value passed from cocoapods-danceui. This is for enable dynamic framework while on Local & CI
is_local_dynamic = defined?(danceui_use_dynamic?) ? danceui_use_dynamic? : false
is_dynamic = is_local_dynamic
build_library_for_distribution = '$(BUILD_LIBRARY_FOR_DISTRIBUTION_$(CONFIGURATION))'
if defined?(enable_distribution?)
  build_library_for_distribution = enable_distribution? ? 'YES' : build_library_for_distribution
end
Pod::Spec.new do |s|
  s.name = 'DanceUI'
  s.version = DanceUI::PodEnv.version
  s.summary = 'DSL'

  s.description = <<-DESC
    TODO: Add long description of the pod here.
  DESC

  s.homepage = 'https://github.com/bytedance/DanceUI'
  s.license = { type: 'Apache', file: 'LICENSE' }
  s.author = { 'bytedance' => 'bytedance@bytedance.com' }
  s.source = { git: '', branch: 'release_' + s.version.to_s }

  s.user_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => [
      '-load-plugin-executable',
      "${PODS_ROOT}/DanceUIMacros/.product/DanceUIMacros-tool#DanceUIMacros",
    ],
  }
  s.pod_target_xcconfig = {
    'USER_HEADER_SEARCH_PATHS' => '"$(PODS_TARGET_SRCROOT)/../DanceUIDependencies/boost" ' +
                                  '"$(PODS_ROOT)/" ',
    'HEADER_SEARCH_PATHS' => '"$(PODS_TARGET_SRCROOT)/../DanceUIDependencies/boost" "$(PODS_ROOT)/DanceUIRuntime/Sources/DanceUIRuntime/include/"',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'ENABLE_NS_ASSERTIONS' => 'YES',
    'OTHER_CPLUSPLUSFLAGS' => '$(OTHER_CFLAGS) -fno-aligned-allocation',
    'SWIFT_ENFORCE_EXCLUSIVE_ACCESS' => 'off',
    'ARCHS' => '$(ARCHS_STANDARD_64_BIT)',

    'BUILD_LIBRARY_FOR_DISTRIBUTION_ReleaseBits' => 'YES',
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => build_library_for_distribution,

    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES_ReleaseBits' => 'YES',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => '$(CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES_$(CONFIGURATION))',

    'CLANG_MODULES_AUTOLINK_ReleaseBits' => 'NO',
    'CLANG_MODULES_AUTOLINK' => '$(CLANG_MODULES_AUTOLINK_$(CONFIGURATION))',

    'ENABLE_TESTABILITY_BinaryCompatibleTest' => 'YES',
    'ENABLE_TESTABILITY_Debug' => 'YES',
    'ENABLE_TESTABILITY' => '$(ENABLE_TESTABILITY_$(CONFIGURATION))',

    'SWIFT_ACTIVE_COMPILATION_CONDITIONS_BinaryCompatibleTest' => 'BINARY_COMPATIBLE_TEST',
    'SWIFT_ACTIVE_COMPILATION_CONDITIONS_Inhouse' => 'DANCE_UI_INHOUSE',
    'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => "$(inherited) $(SWIFT_ACTIVE_COMPILATION_CONDITIONS_$(CONFIGURATION)) #{DanceUI::PodEnv.active_compilation_conditions}",

    'GCC_PREPROCESSOR_DEFINITIONS_Inhouse' => 'DANCE_UI_INHOUSE',
    'GCC_PREPROCESSOR_DEFINITIONS' => "$(inherited) $(GCC_PREPROCESSOR_DEFINITIONS_$(CONFIGURATION)) #{DanceUI::PodEnv.danceui_gcc_preprocessor_definitions}",

    'OTHER_SWIFT_FLAGS' => ([
      '-load-plugin-executable',
      "${PODS_ROOT}/DanceUIMacros/.product/DanceUIMacros-tool#DanceUIMacros",
      '-load-plugin-executable',
      "${PODS_ROOT}/DanceUIInternalMacros/.product/DanceUIInternalMacros-tool#DanceUIInternalMacros",
    ] + Array(DanceUI::PodEnv.other_swift_flags)),
  }

  s.ios.deployment_target = DanceUI::PodEnv.danceuiApp_deployment_target

  s.source_files = [
    'Sources/DanceUI/**/*.{swift}',
    'Sources/DanceUICompose/**/*.{swift}',
    'Sources/DanceUIComposeShims/**/*.{h,c,m,mm}',
    'Sources/DanceUIShims/Public/DanceUICrashLog.h',
    'Sources/DanceUIShims/Public/DanceUIPreloader.h',
    'Sources/DanceUIShims/Public/DanceUIVersionManager.h',
    'Sources/DanceUIShims/Private/*.{h}',
    'Sources/DanceUIShims/Shims/**/*.{h,c,m,mm}',
    'utils/FeatureToggle/features.yml',
    'utils/FeatureToggle/feature_parser.rb',
  ] + (DanceUI::PodEnv.should_contain_docc ? ['Sources/DanceUI/DanceUI.docc/**/*'] : [])

  s.private_header_files = [
    'Sources/DanceUIComposeShims/**/*.{h,hpp}',
    'Sources/DanceUIShims/Private/*.{h}',
    'Sources/DanceUIShims/Shims/VersionManager/*.{h}'
  ]
  s.public_header_files = [
    'Sources/DanceUIShims/Public/DanceUICrashLog.h',
    'Sources/DanceUIShims/Public/DanceUIPreloader.h',
    'Sources/DanceUIShims/Public/DanceUIVersionManager.h',
    'Sources/DanceUIShims/Shims/Kitchen/DanceUIKitchenWrapper.h',
    'Sources/DanceUIShims/Shims/Monitor/DanceUIMonitorProtocol.h',
    'Sources/DanceUIShims/Shims/RuntimeAdditions/RuntimeAdditions.h',
    'Sources/DanceUIShims/Shims/TLS/TLS.h'
  ]

  s.resource_bundles = {
    'DanceUIResources' => ['Sources/DanceUI/Resources/**/*']
  }
  s.requires_arc = true
  s.library = 'c++'
  s.static_framework = !is_dynamic

  s.dependency 'OpenCombine'
  s.dependency 'OpenCombineFoundation'
  s.dependency 'OpenCombineDispatch'
  s.dependency 'MyShims'
  s.dependency 'DanceUIGraph'
  s.dependency 'DanceUIRuntime'
  s.dependency 'DanceUIObservation'
  s.dependency 'DanceUIObservationMacro'
  s.dependency 'Resolver'

  generate_features_script = <<~CMD
    echo PODS_TARGET_SRCROOT="$PODS_TARGET_SRCROOT"
    cd $PODS_TARGET_SRCROOT
    if [ -f utils/FeatureToggle/generate_features.rb ]; then
      ruby utils/FeatureToggle/generate_features.rb
    fi
  CMD
  s.script_phases = [
    {
      name: 'Regenerate DanceUIFeatureDefinitions.swift',
      script: generate_features_script,
      execution_position: :before_compile
    }
  ]
end
