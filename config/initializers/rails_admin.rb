# frozen_string_literal: true

# pgvector columns use a custom :vector type that RailsAdmin does not support.
RailsAdmin::Config::Fields.register_factory do |_parent, properties, _fields|
  properties.type == :vector
end

RailsAdmin.config do |config|
  config.asset_source = :sprockets

  # Never expose Shopify credentials in the admin UI or CSV export.
  config.model "Merchant" do
    exclude_fields :access_token, :refresh_token, :refresh_token_expires_at

    field :shopify_connected do
      label "Shopify connected"
      read_only true

      formatted_value do
        bindings[:object].shopify_connected? ? "Yes" : "No"
      end

      pretty_value do
        formatted_value
      end

      export_value do
        bindings[:object].shopify_connected? ? "Yes" : "No"
      end
    end
  end

  config.actions do
    dashboard
    index
    new
    export
    bulk_delete
    show
    edit
    delete
    show_in_app
  end
end
