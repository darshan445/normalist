module Ai
  class ProfileInterpreter
    SNIPPET_ROWS = 10

    def self.call(merchant:, supplier:, rows:)
      new(merchant: merchant, supplier: supplier, rows: rows).call
    end

    def initialize(merchant:, supplier:, rows:)
      @merchant = merchant
      @supplier = supplier
      @rows = rows
    end

    def call
      headers = @rows.first.keys
      profile = @merchant.supplier_profiles.find_by(supplier: @supplier)

      if profile && !DriftDetector.call(profile, headers)
        profile.touch_last_used!
        return profile.profile_hash
      end

      result = interpret_with_gemini(headers, @rows.first(SNIPPET_ROWS))
      save_profile!(headers, result)
    end

    private

    def interpret_with_gemini(headers, snippet_rows)
      prompt = <<~PROMPT
        You are analyzing a supplier inventory file. Given these column headers and sample rows,
        identify exactly which column contains the supplier product code (SKU/reference) and
        which column contains available stock quantity.

        Headers: #{headers.to_json}
        Sample rows: #{snippet_rows.to_json}

        Respond with JSON only, using these exact keys:
        { "sku_column": "<header name>", "quantity_column": "<header name>" }
      PROMPT

      parsed = GeminiClient.generate_content(prompt)
      sku = parsed["sku_column"].to_s.strip
      qty = parsed["quantity_column"].to_s.strip

      unless headers.include?(sku) && headers.include?(qty)
        raise "Gemini returned invalid columns: #{parsed.inspect}"
      end

      { sku_column: sku, quantity_column: qty }
    end

    def save_profile!(headers, result)
      attributes = {
        sku_column_name: result[:sku_column],
        quantity_column_name: result[:quantity_column],
        raw_headers: headers,
        last_used_at: Time.current
      }

      profile = SupplierProfile.find_by(merchant: @merchant, supplier: @supplier)

      if profile
        profile.update!(attributes)
      else
        SupplierProfile.create!(attributes.merge(merchant: @merchant, supplier: @supplier))
      end

      result
    rescue ActiveRecord::RecordNotUnique
      SupplierProfile.find_by!(merchant: @merchant, supplier: @supplier).update!(attributes)
      result
    end
  end
end
