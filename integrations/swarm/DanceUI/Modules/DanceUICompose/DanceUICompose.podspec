#
# Be sure to run `pod lib lint DanceUICompose.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#
require './Scripts/pod_env'

# "extParams"="tp=dynamic" is an global environment value passed from Components Platform. This is for enabling preview (dynamic framework) while on Components Platform
is_bits_dynamic = ENV['extParams'].nil? ? false : ENV['extParams'].include?('tp=dynamic')
# "danceui_use_dynamic" is an global environment value passed from cocoapods-danceui. This is for enable dynamic framework while on Local & CI
is_local_dynamic = defined?(danceui_use_dynamic?) ? danceui_use_dynamic? : false
is_dynamic = DanceUI::PodEnv.is_cloud_build ? is_bits_dynamic : is_local_dynamic

Pod::Spec.new do |s|
  s.name             = 'DanceUICompose'
  s.version          = DanceUI::PodEnv.version
  s.summary          = 'A short description of DanceUICompose.'

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<~DESC
    TODO: Add long description of the pod here.
  DESC

  s.homepage         = 'https://github.com/retval/DanceUI'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { type: 'MIT', file: 'LICENSE' }
  s.author           = { 'retval' => 'retval@me.com' }
  s.source           = { git: '', branch: 'release_' + s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = DanceUI::PodEnv.danceuiApp_deployment_target

  s.pod_target_xcconfig = {
    'ENABLE_NS_ASSERTIONS' => 'YES',
    'OTHER_CPLUSPLUSFLAGS' => '$(OTHER_CFLAGS) -fno-aligned-allocation',
    'SWIFT_ENFORCE_EXCLUSIVE_ACCESS' => 'off',
    'ARCHS' => '$(ARCHS_STANDARD_64_BIT)',
    'BUILD_LIBRARY_FOR_DISTRIBUTION_ReleaseBits' => 'YES',
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => '$(BUILD_LIBRARY_FOR_DISTRIBUTION_$(CONFIGURATION))',

    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES_ReleaseBits' => 'YES',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => '$(CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES_$(CONFIGURATION))',

    'CLANG_MODULES_AUTOLINK_ReleaseBits' => 'NO',
    'CLANG_MODULES_AUTOLINK' => '$(CLANG_MODULES_AUTOLINK_$(CONFIGURATION))',

    'OTHER_SWIFT_FLAGS_ReleaseBits' => "-no-verify-emitted-module-interface",
    'OTHER_SWIFT_FLAGS' => "$(inherited) #{DanceUI::PodEnv.danceui_extension_other_swift_flags} #{DanceUI::PodEnv.other_swift_flags}",

    'SWIFT_ACTIVE_COMPILATION_CONDITIONS_Inhouse' => 'DANCE_UI_INHOUSE',
    'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => "$(inherited) $(SWIFT_ACTIVE_COMPILATION_CONDITIONS_$(CONFIGURATION)) #{DanceUI::PodEnv.active_compilation_conditions}",

    'GCC_PREPROCESSOR_DEFINITIONS_Inhouse' => 'DANCE_UI_INHOUSE',
    'GCC_PREPROCESSOR_DEFINITIONS' => "$(inherited) $(GCC_PREPROCESSOR_DEFINITIONS_$(CONFIGURATION)) #{DanceUI::PodEnv.danceui_extension_gcc_preprocessor_definitions}",
  }

  s.requires_arc = true
  s.library = 'c++'
  s.dependency 'DanceUI'
  s.dependency 'Resolver', '>= 0.0.1'

  s.subspec 'Basic' do |basic|
    basic.source_files = [
      'Sources/DanceUICompose/**/*.swift',
      'Sources/DanceUIComposeShims/**/*.{h,m,mm}'
    ]
    basic.public_header_files ='Sources/DanceUIComposeShims/**/*.h'

    basic.resource_bundles = {
      'DanceUIComposeResources' => ['Sources/DanceUICompose/Resources/**/*']
    }
  end

  # if(DanceUI::PodEnv.should_contain_docc)
  #  s.subspec 'Documentation' do |d|
  #    d.source_files = ['Sources/DanceUIExtension/DanceUIExtension.docc/**/*']
  #  end
  # end`
end
