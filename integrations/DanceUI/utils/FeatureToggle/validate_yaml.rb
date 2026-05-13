# frozen_string_literal: true

require_relative 'feature_parser'

result = DanceUI::Feature.validate_yaml
if result != ''
  system('rootPath=$(git rev-parse --show-toplevel) && source $rootPath/utils/PreChecker/pre-checker-kit.sh && markResultError "Features.yml check failed"')
  raise result
end

unless DanceUI::Feature.feature_updated?
  prompt = 'DanceUIFeatures.swift is not latest and needs to be updated'
  command = <<-CMD
  rootPath=$(git rev-parse --show-toplevel)
  source $rootPath/utils/PreChecker/pre-checker-kit.sh
  markResultError #{prompt}
  CMD
  system(command)
  raise prompt
end
