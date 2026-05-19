# frozen_string_literal: true

# Ensure pgvector types and Neighbor hooks are registered before any model loads.
require "neighbor"
require "pgvector"
