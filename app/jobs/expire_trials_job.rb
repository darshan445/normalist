# frozen_string_literal: true

class ExpireTrialsJob < ApplicationJob
  queue_as :default

  def perform
    expired_merchants = Merchant
      .where(plan_status: "trialing")
      .where(trial_ends_at: ...Time.current)

    expired_merchants.find_each do |merchant|
      Rails.logger.info(
        "[ExpireTrialsJob] trial expired merchant=#{merchant.id}"
      )
    end

    Rails.logger.info(
      "[ExpireTrialsJob] checked #{expired_merchants.count} expired trials"
    )
  end
end
