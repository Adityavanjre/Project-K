# frozen_string_literal: true

require_relative '../utils/FeatureToggle/feature_parser'

module DanceUI
  class PodEnv
    # DanceUI 版本
    # DanceUIExtension 也用这个版本
    def self.version
      "0.14.12" # auto-modified by version-manager.js
    end

    def self.commit_id
      begin
        return `git rev-parse --short=8 HEAD`.strip!
      rescue
        return "(Undefiened Commit Id)"
      end
    end

    def self.last_valid_commit_id
      begin
        return `git rev-parse --short=8 HEAD~`.strip!
      rescue
        return "(Undefiened Commit Id)"
      end
    end

    # 检查是否云构建
    def self.is_cloud_build
      ENV['TASK_ID'] && ENV['WORKSPACE']
    end

    def self.is_bits_components
      ENV['from_type_string'] == 'components_platform'
    end

    # 检查是否 CI 环境，这个环境变量由所有 CI 任务注入
    def self.is_ci
      is_cloud_build && ENV['DANCEUI_CI']
    end

    # 发布环境
    def self.is_release

    end

    def self.test_deployment_target
      is_release ? '13.0' : '16.0'
    end

    def self.danceuiApp_deployment_target
      is_release ? '13.0' : '13.0'
    end

    def self.other_swift_flags
      is_ci ? "-coverage-prefix-map #{Dir.pwd}=/COV_PLACEHOLDER" : ''
    end

    def self.danceui_extension_other_swift_flags
      # The interpolation flag aim to solve DanceUI CI coverage error.
      # But jojo+bazel handle the interpolation flag incorrectly.
      is_ci ? "$(OTHER_SWIFT_FLAGS_$(CONFIGURATION))" : ""
    end

    def self.extra_inhouse_macro # 处理 DANCE_UI_INHOUSE 相关注入逻辑
      if !ENV['FORCE_OPEN_DANCE_UI_INHOUSE'].nil? # 使用环境变量 FORCE_OPEN_DANCE_UI_INHOUSE 控制手动打开
        return "DANCE_UI_INHOUSE"
      end
      if !ENV['FORCE_CLOSE_DANCE_UI_INHOUSE'].nil? # 使用环境变量 FORCE_CLOSE_DANCE_UI_INHOUSE 控制手动关闭
        return ""
      end
      if self.is_bits_components # 组件平台上走组件平台配置
        return ""
      end
      if $__danceui_use_source # 当打开 cocoapods-danceui 的 danceui_use_source! 时打开
        return "DANCE_UI_INHOUSE"
      end
      return ""
    end

    def self.danceui_macros
      return " " + [self.extra_inhouse_macro].join(" ")
    end

    # Version Manager defines: handle DanceUI_POD_VERSION and DanceUI_COMMIT_ID
    def self.version_manager_danceui_gcc_preprocessor_definitions

      version_raw = is_bits_components ? "" : "DanceUI_POD_VERSION=@\\\"#{self.version}-#{self.artifact}\\ (local)\\\""

      commit_raw = ""

      if is_bits_components # read commit id from Bits Job Environment
        commit_id = ENV['WORKFLOW_REPO_COMMIT'][0,8]
      else
        commit_id = self.commit_id
      end
      # use DanceUI_COMMIT_ID=@"486a87d6"
      commit_raw = "DanceUI_COMMIT_ID=@\\\"#{commit_id}\\\""
      return " #{version_raw} #{commit_raw}"
    end

    # Version Manager defines: handle DanceUIExtension_POD_VERSION and DanceUIExtension_COMMIT_ID
    def self.version_manager_danceui_extension_gcc_preprocessor_definitions

      version_raw = is_bits_components ? "" : "DanceUIExtension_POD_VERSION=@\\\"#{self.version}-#{self.artifact}\\ (local)\\\""

      commit_raw = ""
      if is_bits_components
        # read commit id from Release Branch.
        # WORKFLOW_REPO_BRANCH: feature/add-version-logger_4325d52
        branchName = ENV['WORKFLOW_REPO_BRANCH']
        # ['feature/add-version-logger', '4325d52']
        splitBranchName = branchName.split("_")

        commit_id = splitBranchName[-1]
        # use DanceUIExtension_COMMIT_ID=@"486a87d6"
        commit_raw = "DanceUIExtension_COMMIT_ID=@\\\"#{commit_id}\\\""
      else
        commit_id = self.commit_id
        # use DanceUI_COMMIT_ID=@"486a87d6"
        commit_raw = "DanceUIExtension_COMMIT_ID=@\\\"#{commit_id}\\\""
      end
      return " #{version_raw} #{commit_raw}"
    end

    def self.artifact
      return DanceUI::Feature.current_artifact
    end

    # SWIFT_ACTIVE_COMPILATION_CONDITIONS
    def self.active_compilation_conditions
      DanceUI::Feature.compile_features_of(self.artifact) + self.danceui_macros
    end

    # common GCC_PREPROCESSOR_DEFINITIONS
    def self.common_gcc_preprocessor_definitions
      DanceUI::Feature.compile_features_of(self.artifact) + self.danceui_macros
    end

    def self.danceui_extension_gcc_preprocessor_definitions
      self.common_gcc_preprocessor_definitions + self.version_manager_danceui_extension_gcc_preprocessor_definitions
    end

    def self.danceui_gcc_preprocessor_definitions
      self.common_gcc_preprocessor_definitions + self.version_manager_danceui_gcc_preprocessor_definitions
    end

    # check cocoapods version > 1.12.0
    def self.cocoapods_version_number_geater_than_1_12_0
      return Gem::Version.new(Pod::VERSION) >= Gem::Version.new('1.12.0')
    end

    # docc source files need cocoapods > 1.12.0
    def self.should_contain_docc
      return self.cocoapods_version_number_geater_than_1_12_0 && !self.is_bits_components
    end

    def self.is_in_jojo
      return !ENV['JOJO_ENABLE_JPM'].to_s.empty?
    end

    def self.is_in_bitsky
      return !ENV['BitSky'].to_s.empty?
    end
  end
end
