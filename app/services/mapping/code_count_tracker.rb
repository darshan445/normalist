# frozen_string_literal: true

require "set"

module Mapping
  class CodeCountTracker
    def initialize
      @resolved = Set.new
      @unresolved = Set.new
    end

    def mark_resolved!(code)
      normalized = normalize(code)
      return if normalized.nil?

      @unresolved.delete(normalized)
      @resolved << normalized
    end

    def mark_unresolved!(code)
      normalized = normalize(code)
      return if normalized.nil?
      return if @resolved.include?(normalized)

      @unresolved << normalized
    end

    def resolved_count
      @resolved.size
    end

    def unresolved_count
      @unresolved.size
    end

    def unique_code_count
      @resolved.size + @unresolved.size
    end

    private

    def normalize(code)
      normalized = code.to_s.strip
      normalized.presence
    end
  end
end
