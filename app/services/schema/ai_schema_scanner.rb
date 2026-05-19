# frozen_string_literal: true

module Schema
  class AiSchemaScanner
    SYSTEM_PROMPT = <<~PROMPT.freeze
      You are an expert data-mapping engine for an e-commerce inventory sync system.

      Your task is to analyze supplier file columns. Each column includes its header name and several sample cell values from real data rows. You MUST use both the header name and the sample values to decide which supplier column maps to each core system key.

      Our Core System Keys to Map:
      1. supplier_unique_column: The primary unique identifier/SKU for the item.
      2. supplier_barcode_column: Global barcodes like UPC, EAN, or GTIN (Return null if not present).
      3. supplier_quantity_column: The current stock inventory level or quantity available.
      4. title: The descriptive product name (Return null if not present).
      5. color: The product's variant color (Return null if not present).
      6. size: The product's variant size (Return null if not present).

      How to recognize each key from sample values (use these patterns):
      - supplier_unique_column: vendor style codes, alphanumeric SKUs, item references that uniquely identify a product variant (e.g. "AERO-BLK-09", "SKU-12345", "VND-9982", "XYZ-4410-BLK-9").
      - supplier_barcode_column: 8–14 digit numeric barcodes, UPC/EAN/GTIN values (e.g. "1234567890123", "040000123456"). Return null if no column matches.
      - supplier_quantity_column: whole-number stock counts, inventory on hand (e.g. "45", "0", "120", "3"). Usually numeric, not product descriptions.
      - title: human-readable product names or descriptions (e.g. "Air Runner Sneaker", "Foam Insole Grey", "Running Socks"). Return null if no description column exists.
      - color: color names, abbreviations, or slots (e.g. "Black", "BLK", "Navy", "Grey"). Return null if not present.
      - size: size labels (e.g. "9", "10.5", "L", "Medium", "OS", "One Size"). Return null if not present.

      CRITICAL RULES:
      - Every mapped value MUST be the exact "Header" string from the supplier file columns provided (character-for-character).
      - Do NOT return sample cell values as column names (e.g. if sample values are "RED" or "S", those are data — not headers).
      - Do NOT invent shortened labels (e.g. "SKU") unless that is literally the header text in the file.
      - Use null for optional keys when no matching header exists.

      Respond ONLY with a valid JSON object matching this exact schema. Do not include markdown code blocks, text explanations, or preamble.

      Desired JSON Output Format:
      {
        "supplier_unique_column": "string",
        "supplier_barcode_column": "string or null",
        "supplier_quantity_column": "string",
        "supplier_attributes": {
          "title": "string or null",
          "color": "string or null",
          "size": "string or null"
        }
      }
    PROMPT

    def self.call(rows:)
      new(rows: rows).call
    end

    def initialize(rows:)
      @rows = rows
      @headers = @rows.first&.keys || []
    end

    def call
      parsed = Ai::OpenaiClient.chat_json(
        system_prompt: SYSTEM_PROMPT,
        user_prompt: build_user_prompt
      )

      resolved = resolve_mapping(parsed)
      validate_resolved_mapping!(resolved)
      resolved
    end

    private

    def build_user_prompt
      snippet = RowSnippetBuilder.call(rows: @rows)
      columns_text = format_columns_for_prompt(snippet["columns"])

      <<~PROMPT
        Below are supplier file columns with sample cell values taken from real data rows.
        For each column, read the header and inspect the sample values before choosing mappings.

        #{columns_text}

        Exact headers you may map to (use these strings exactly in your JSON response):
        #{@headers.map { |header| "- #{header.inspect}" }.join("\n")}
      PROMPT
    end

    def format_columns_for_prompt(columns)
      return "No columns found." if columns.blank?

      columns.map.with_index(1) do |column, index|
        header = column["header"]
        samples = Array(column["sample_values"]).compact
        sample_line = if samples.any?
                        samples.map { |value| %("#{value}") }.join(", ")
                      else
                        "(no sample values)"
                      end

        <<~COLUMN.strip
          Column #{index}:
            Header: #{header}
            Sample values: #{sample_line}
        COLUMN
      end.join("\n\n")
    end

    def validate_resolved_mapping!(resolved)
      if resolved["supplier_unique_column"].blank?
        raise ArgumentError, "Could not resolve supplier_unique_column to a file header"
      end

      if resolved["supplier_quantity_column"].blank?
        raise ArgumentError, "Could not resolve supplier_quantity_column to a file header"
      end
    end

    def resolve_mapping(parsed)
      unless parsed.is_a?(Hash)
        raise ArgumentError, "OpenAI schema response must be a JSON object"
      end

      attributes = parsed["supplier_attributes"]
      raise ArgumentError, "supplier_attributes must be an object" unless attributes.is_a?(Hash)

      {
        "supplier_unique_column" => resolve_header(parsed["supplier_unique_column"], required: true),
        "supplier_barcode_column" => resolve_header(parsed["supplier_barcode_column"]),
        "supplier_quantity_column" => resolve_header(parsed["supplier_quantity_column"], required: true),
        "supplier_attributes" => {
          "title" => resolve_header(attributes["title"]),
          "color" => resolve_header(attributes["color"]),
          "size" => resolve_header(attributes["size"])
        }
      }
    end

    def resolve_header(candidate, required: false)
      return nil if candidate.blank?

      matched = header_lookup[candidate.to_s.strip]
      matched ||= header_lookup.values.find do |header|
        normalize_header(header) == normalize_header(candidate)
      end

      return matched if matched

      if required
        raise ArgumentError,
              "Could not match #{candidate.inspect} to a file header. " \
              "Available headers: #{@headers.map(&:inspect).join(', ')}"
      end

      nil
    end

    def header_lookup
      @header_lookup ||= @headers.index_by { |header| header.to_s.strip }
    end

    def normalize_header(value)
      value.to_s.strip.downcase.gsub(/[\s_\-]+/, "")
    end

  end
end
