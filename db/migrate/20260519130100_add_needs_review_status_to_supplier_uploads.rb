# frozen_string_literal: true

class AddNeedsReviewStatusToSupplierUploads < ActiveRecord::Migration[8.1]
  def up
    # status is a string column — no enum change required; model validation documents needs_review.
  end

  def down
  end
end
