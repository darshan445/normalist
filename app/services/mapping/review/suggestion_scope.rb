# frozen_string_literal: true

module Mapping
  module Review
    module SuggestionScope
      THRESHOLD = 0.5

      def self.apply(scope, filter)
        case filter.to_s
        when "suggested"
          scope.where("confidence_score >= ?", THRESHOLD)
        when "unsuggested"
          scope.where("confidence_score IS NULL OR confidence_score < ?", THRESHOLD)
        else
          scope
        end
      end
    end
  end
end
