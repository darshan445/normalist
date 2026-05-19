# frozen_string_literal: true

class AddHnswIndexOnVariantsEmbedding < ActiveRecord::Migration[8.1]
  def change
    add_index :variants,
              :embedding,
              using: :hnsw,
              opclass: :vector_cosine_ops,
              name: "index_variants_on_embedding_hnsw"
  end
end
