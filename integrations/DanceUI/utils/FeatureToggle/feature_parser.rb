# frozen_string_literal: true

require 'yaml'

module DanceUI
  # Feature 管理的能力
  class Feature
    def self.yaml_content
      YAML.safe_load(File.open("#{__dir__}/features.yml"))
    rescue StandardError
      nil
    end

    def self.current_artifact
      if ENV['CLOUD_BUILD_STEP_NAME'] == 'iOS组件升级官方插件' || !ENV['RELEASE_TEST'].nil?
        release_artifact
      else
        ENV['danceui_artifact'] || 'main' # 默认值
      end
    end

    # 获取组件平台发版时指定的 artifict
    def self.release_artifact
      artifact_env = ENV['extParams']&.split(';')&.find do |kv|
        kv.start_with?('artifact=')
      end
      artifact_env&.delete_prefix('artifact=') || 'main'
    end

    # @note 判断 features.yml 是否合法
    # 1. 只能使用已经定义的 Feature
    # @return String 空字符串表示没问题，否则表示报错内容
    # 1: yaml invalid or not exist
    def self.validate_yaml
      yaml = yaml_content
      return 'Config Invalid or not exist' if yaml.nil?

      artifacts = yaml&.[]('artifacts')
      return '' if artifacts.nil?

      all_features = yaml&.[]('features') || []
      parsed_features_result = validate_features(all_features)
      return parsed_features_result.first if parsed_features_result.first != ''

      parsed_features = parsed_features_result[1].map do |e|
        e['name']
      end
      artifacts.each_value do |artifact|
        result = validate_artifact(artifact, parsed_features)
        return result if result != ''
      end
      ''
    end

    def self.validate_features(features)
      valid_flags = []
      features&.each do |feature|
        result = validate_flag(feature)
        return [result, []] if result != ''

        valid_flags << feature
      end

      ['', valid_flags]
    end

    def self.validate_flag(flag)
      return "missing name of feature: #{flag.to_yaml}" if flag['name'].nil?
      return "missing desc of feature: #{flag.to_yaml}" if flag['desc'].nil?
      return "missing owner of feature: #{flag.to_yaml}" if flag['owner'].nil?
      return "missing module of feature: #{flag.to_yaml}" if flag['module'].nil?
      return "missing type of feature: #{flag.to_yaml}" if flag['type'].nil?
      return "missing value of feature: #{flag.to_yaml}" if flag['value'].nil?

      ''
    end

    def self.validate_group(group)
      return "missing name of group: #{group.to_yaml}" if group['name'].nil?

      validate_features(group['features'])
    end

    def self.validate_artifact(artifact, all_runtime_features)
      return '' if artifact.nil?

      artifact_features = artifact['features'] || []
      artifact_features.each do |artifact_feature|
        artifact_feature_name = artifact_feature['name']
        return "missing feature name of feature: #{artifact_feature.to_yaml}" if artifact_feature_name.nil?
        unless all_runtime_features.any?(artifact_feature_name)
          return "unknown runtime feature: #{artifact_feature_name}"
        end
      end

      ''
    end

    # 支持 name 转换成 UP_SNAKE_CASE，后续推全量
    def self.compile_features_of(artifact)
      yaml = yaml_content
      all_features = yaml&.[]('features') || []
      parsed_features_result = validate_features(all_features)
      return '' if parsed_features_result[0] != ''

      artifact_overrides = yaml.dig('artifacts', artifact, 'features') || []
      yaml_features = []
      parsed_features_result[1].each do |feature|
        override = artifact_overrides.find { |override| override['name'] == feature['name'] }
        is_compile_feature = feature&.[]('type') == 'Bool'
        enable = override&.[]('enable') || feature&.[]('enable')

        name = feature&.[]('name')
        name = "FEAT_#{name.camel_to_up_snake_case}"
        yaml_features.append(name) if (is_compile_feature && enable) || artifact == 'all'
      end
      if artifact == 'all'
        get_all_artifact_name.each do |a|
          yaml_features.append("FEAT_#{a.camel_to_up_snake_case}")
        end
      end
      artifact = "FEAT_#{artifact.camel_to_up_snake_case}"
      yaml_features.append(artifact)
      yaml_features.join(' ')
    end

    # 获取所有的 artifact 名字
    def self.get_all_artifact_name
      yaml = yaml_content
      all_artifacts = yaml&.[]('artifacts') || []
      all_artifacts.keys
    end

    # 生成的 DanceUIFeatureDefinitions.swift 文件的路径
    def self.generated_features_filepath
      "#{__dir__}/../../Sources/DanceUI/Services/FeatureToggle/DanceUIFeatureDefinitions.swift"
    end

    # 判断当前的 DanceUIFeatures.swift 是不是最新的
    def self.feature_updated?
      latest = runtime_feature_content_of(current_artifact)
      current = File.read(generated_features_filepath)
      latest == current
    end

    def self.generate_feature_of(artifact)
      new_content = runtime_feature_content_of(artifact)
      old_content = File.read(generated_features_filepath)
      File.write(generated_features_filepath, new_content) if new_content != old_content
    end

    def self.runtime_feature_content_of(artifact)
      yaml = yaml_content
      overrides = yaml.dig('artifacts', artifact, 'features')
      <<~TEMPLATE
        //
        //  DanceUIFeatureDefinitions.swift
        //  DanceUI
        //
        //  DO NOT EDIT MANUALLY!!!!!!!!!!
        //  Auto created from features.yml
        //
        //  module: Foundation


        #{_gen_group('DanceUIFeatureDefinitions', yaml['features'], overrides)}
      TEMPLATE
    end

    def self._gen_group(name, features, overrides)
      return '' if features.nil?

      content = features.map do |e|
        _gen_feature(e, overrides&.find { |f| f['name'] == e['name'] }) if !e['complieOnly']
      end

      <<~TEMPLATE
        #{content.join("\n")}
      TEMPLATE
    end

    def self._gen_feature(data, override = nil)
      value = override&.[]('value') || data['value']
      value = "\"#{value}\"" if value.is_a? String
      keyName = data['name'].upcase_first
      
      createFeature = data['type'] == 'Bool'
      
      if createFeature
          <<~TEMPLATE
          /// #{data['desc']}
          ///
          /// use the Feature:
          ///
          ///     DanceUIFeature.#{data['name']}
          ///
          /// mock the Feature Enable:
          ///
          ///     FeatureMock.mock(#{keyName}Key.self, value: true)
          ///
          /// - owner: @#{data['owner']}
          /// - module: #{data['module']}
          @available(iOS 13.0, *)
          internal struct #{keyName}Key: SettingsKey {
              
              internal static let key: String = "\DanceUI_Feature_#{keyName}\"
              
              internal static var defaultValue: #{data['type']} {
                  #{value}
              }
          }
          
          @available(iOS 13.0, *)
          extension DanceUIFeature where K == #{keyName}Key {
              internal static var #{data['name']}: Self.Type {
                  Self.self
              }
          }
          
          TEMPLATE
      else
          <<~TEMPLATE
          /// #{data['desc']}
          ///
          /// use the Feature:
          ///
          ///     DanceUIFeature.#{data['name']}
          ///
          /// mock the Feature Enable:
          ///
          ///     FeatureMock.mock(#{keyName}Key.self, value: true)
          ///
          /// - owner: @#{data['owner']}
          /// - module: #{data['module']}
          @available(iOS 13.0, *)
          internal struct #{keyName}Key: SettingsKey {
              
              internal static let key: String = "\DanceUI_Feature_#{keyName}\"
              
              internal static var defaultValue: #{data['type']} {
                  #{value}
              }
          }
          TEMPLATE
      end
    end
  end
end

# DanceUI extension
class String
  def underscore
    gsub(/::/, '/')
      .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
      .gsub(/([a-z\d])([A-Z])/, '\1_\2')
      .tr('-', '_')
      .downcase
  end

  def camel_to_up_snake_case
    underscore.split('_').map(&:upcase).join('_')
  end
  
  def upcase_first
    return self if empty?
    dup.tap {|s| s[0] = s[0].upcase }
  end
end
