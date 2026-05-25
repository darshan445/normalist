# frozen_string_literal: true

class SecurePageKeyAuth
  COOKIE_NAME = "secure_page_auth"

  def initialize(app, cookie_name: COOKIE_NAME, cookie_path: "/")
    @app = app
    @cookie_name = cookie_name
    @cookie_path = cookie_path
  end

  def call(env)
    request = Rack::Request.new(env)
    expected = ENV["SECURE_PAGE_KEY"].to_s

    if expected.blank?
      return unauthorized unless Rails.env.development?

      return @app.call(env)
    end

    unless authorized?(request, expected)
      return unauthorized
    end

    status, headers, body = @app.call(env)

    unless cookie_valid?(request, expected)
      response = Rack::Response.new(body, status, headers)
      response.set_cookie(
        @cookie_name,
        value: auth_token(expected),
        path: @cookie_path,
        httponly: true,
        same_site: :lax,
        secure: Rails.env.production?
      )
      response.finish
    else
      [ status, headers, body ]
    end
  end

  private

  def authorized?(request, expected)
    key_matches?(request.params["key"], expected) || cookie_valid?(request, expected)
  end

  def key_matches?(provided, expected)
    return false if provided.blank?

    secure_compare(provided, expected)
  end

  def cookie_valid?(request, expected)
    secure_compare(request.cookies[@cookie_name].to_s, auth_token(expected))
  end

  def auth_token(expected)
    ::Digest::SHA256.hexdigest("secure_page:#{expected}")
  end

  def secure_compare(provided, expected)
    return false if expected.blank? || provided.blank?

    ActiveSupport::SecurityUtils.secure_compare(
      ::Digest::SHA256.hexdigest(provided),
      ::Digest::SHA256.hexdigest(expected)
    )
  end

  def unauthorized
    [ 401, { "Content-Type" => "text/plain" }, [ "Unauthorized" ] ]
  end
end
