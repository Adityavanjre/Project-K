# frozen_string_literal: true

require_relative 'feature_parser'

artifact = DanceUI::Feature.current_artifact
DanceUI::Feature.generate_feature_of(artifact)
