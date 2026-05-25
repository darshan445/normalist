# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecurePageKeyAuth do
  let(:app) { ->(_env) { [ 200, { "Content-Type" => "text/plain" }, [ "OK" ] ] } }
  let(:middleware) { described_class.new(app) }

  around do |example|
    original = ENV["SECURE_PAGE_KEY"]
    ENV["SECURE_PAGE_KEY"] = "test-secret"
    example.run
  ensure
    ENV["SECURE_PAGE_KEY"] = original
  end

  it "allows access with a valid key query param" do
    status, = middleware.call(Rack::MockRequest.env_for("/sidekiq?key=test-secret"))

    expect(status).to eq(200)
  end

  it "rejects access without a valid key" do
    status, _headers, body = middleware.call(Rack::MockRequest.env_for("/sidekiq"))

    expect(status).to eq(401)
    expect(body.first).to eq("Unauthorized")
  end

  it "allows access with a valid auth cookie" do
    token = Digest::SHA256.hexdigest("secure_page:test-secret")
    env = Rack::MockRequest.env_for("/sidekiq", "HTTP_COOKIE" => "secure_page_auth=#{token}")

    status, = middleware.call(env)

    expect(status).to eq(200)
  end
end
