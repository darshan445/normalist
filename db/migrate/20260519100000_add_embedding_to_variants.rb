# frozen_string_literal: true

class AddEmbeddingToVariants < ActiveRecord::Migration[8.1]
  def up
    enable_extension "vector"

    add_column :variants, :embedding, :vector, limit: 1536
    add_column :variants, :embedded_at, :datetime
  end

  def down
    remove_column :variants, :embedded_at
    remove_column :variants, :embedding

    disable_extension "vector"
  end
end
