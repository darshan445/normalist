# frozen_string_literal: true

module Uploads
  class StagePresenter
    LABELS = {
      "parsing" => "Parsing file...",
      "ai_detection" => "Detecting columns with AI...",
      "profile_cache" => "Loading column profile...",
      "resolving" => "Resolving supplier codes...",
      "complete" => "Done!",
      "failed" => "Upload failed"
    }.freeze

    ORDER = %w[parsing profile_cache ai_detection resolving].freeze

    def self.call(upload)
      new(upload).call
    end

    def initialize(upload)
      @upload = upload
    end

    def call
      key = stage_key
      {
        stage_key: key,
        stage_label: LABELS[key] || @upload.stage.to_s.presence || "Processing",
        progress_percent: progress_for(key),
        steps: build_steps(key)
      }
    end

    private

    def stage_key
      return "failed" if @upload.status == "failed"
      return "complete" if @upload.status.in?(%w[completed needs_review])

      raw = @upload.stage.to_s.strip
      return "parsing" if raw.blank?

      return raw if LABELS.key?(raw)

      return "parsing" if raw.match?(/pars/i)
      return "ai_detection" if raw.match?(/discover|detect|schema|column/i)
      return "profile_cache" if raw.match?(/profile|layout|cached/i)
      return "resolving" if raw.match?(/match|resolv|unmatched|phase/i)

      "resolving"
    end

    def progress_for(key)
      return 100 if key == "complete"
      return 10 if key == "failed"

      idx = ORDER.index(key) || ORDER.index("resolving") || 0
      (((idx + 1).to_f / ORDER.size) * 100).round.clamp(10, 90)
    end

    def build_steps(current_key)
      profile_key = current_key == "ai_detection" ? "ai_detection" : "profile_cache"

      [
        build_step("parsing", "File parsed", current_key),
        build_step(profile_key, profile_key == "ai_detection" ? "Column profile detected" : "Column profile loaded", current_key),
        build_step("resolving", "Resolving codes", current_key)
      ]
    end

    def build_step(key, label, current_key)
      state = step_state(key, current_key)
      suffix = key == "parsing" && @upload.row_count.present? && state != "pending" ? " — #{@upload.row_count} rows found" : ""

      { key: key, label: "#{label}#{suffix}", state: state }
    end

    def step_state(key, current_key)
      return "done" if @upload.status.in?(%w[completed needs_review])
      return "failed" if @upload.status == "failed" && key == current_key

      current_position = ORDER.index(current_key) || ORDER.index("resolving") || 0
      step_position = ORDER.index(key) || 2

      return "done" if step_position < current_position
      return "active" if key == current_key || (key == "profile_cache" && current_key == "ai_detection")
      return "active" if key == "resolving" && current_key == "resolving"

      "pending"
    end
  end
end
