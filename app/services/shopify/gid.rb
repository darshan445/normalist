# frozen_string_literal: true

module Shopify
  module Gid
    module_function

    def build(type, id)
      "gid://shopify/#{type}/#{numeric_id(id)}"
    end

    def numeric_id(gid_or_id)
      value = gid_or_id.to_s
      return value.split("/").last if value.start_with?("gid://")

      value
    end

    def inventory_item(id)
      build("InventoryItem", id)
    end

    def location(id)
      build("Location", id)
    end

    def app_subscription(id)
      build("AppSubscription", id)
    end
  end
end
