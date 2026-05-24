# frozen_string_literal: true

module AuthenticatedController
  extend ActiveSupport::Concern

  included do
    include BillingGate
  end
end
