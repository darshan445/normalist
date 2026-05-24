# frozen_string_literal: true

class ExpireCancelledSubscriptionsJob < ApplicationJob
  queue_as :default

  def perform
    expired_count = 0

    Subscription.cancellation_pending.find_each do |subscription|
      next if subscription.within_paid_period?

      subscription.expire_if_period_ended!
      expired_count += 1

      Rails.logger.info(
        "[ExpireCancelledSubscriptionsJob] expired subscription=#{subscription.id} " \
        "merchant=#{subscription.merchant_id}"
      )
    end

    Rails.logger.info(
      "[ExpireCancelledSubscriptionsJob] expired #{expired_count} subscriptions"
    )
  end
end
