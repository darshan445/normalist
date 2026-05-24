# frozen_string_literal: true

module Billing
  class PlanChangeRecorder
    def self.call(merchant:, to_plan:, reason:, subscription: nil, initiated_by: "system", note: nil)
      new(
        merchant: merchant,
        to_plan: to_plan,
        reason: reason,
        subscription: subscription,
        initiated_by: initiated_by,
        note: note
      ).record
    end

    def initialize(merchant:, to_plan:, reason:, subscription: nil, initiated_by: "system", note: nil)
      @merchant = merchant
      @to_plan = to_plan
      @reason = reason
      @subscription = subscription
      @initiated_by = initiated_by
      @note = note
    end

    def record
      from_plan = @merchant.current_plan&.key

      plan_change = PlanChange.create!(
        merchant: @merchant,
        subscription: @subscription,
        from_plan: from_plan,
        to_plan: @to_plan,
        reason: @reason,
        initiated_by: @initiated_by,
        note: @note
      )

      Rails.logger.info(
        "[PlanChangeRecorder] " \
        "merchant=#{@merchant.id} " \
        "from=#{from_plan} " \
        "to=#{@to_plan} " \
        "reason=#{@reason} " \
        "initiated_by=#{@initiated_by}"
      )

      plan_change
    end
  end
end
