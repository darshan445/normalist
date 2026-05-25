# frozen_string_literal: true

# pgvector columns use a custom :vector type that RailsAdmin does not support.
RailsAdmin::Config::Fields.register_factory do |_parent, properties, _fields|
  properties.type == :vector
end

RailsAdmin.config do |config|
  config.asset_source = :sprockets

  ### More at https://github.com/railsadminteam/rails_admin/wiki/Base-configuration

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
