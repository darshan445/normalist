# frozen_string_literal: true

module Billing
  class ChargeCreationError < StandardError
    attr_reader :user_message

    def initialize(user_message, original: nil)
      @user_message = user_message
      super(original&.message || user_message)
    end
  end
end
