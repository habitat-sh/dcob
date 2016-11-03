require "spec_helper"

describe Dcob do
  it "has a version number" do
    expect(Dcob::VERSION).not_to be nil
  end
end

describe "DCO Bot webhook server" do
  include Rack::Test::Methods

  def app
    Dcob::Server
  end

  context "random connections" do
    it "get a 500" do
      get "/"
      expect(last_response).to_not be_ok
    end
  end

  context "processing repository events" do
    let(:headers) do
      { "CONTENT_TYPE" => "application/json",
        "X-GitHub-Event" => "repository",
        "HTTP_X_HUB_SIGNATURE" => "nope" }
    end

    it "does nothing with an empty post to repo webhook" do
      post "/payload", "", headers
      expect(last_response.status).to eq(500)
    end

    it "adds the push payload webhook to a new public repository" do
      payload_body = File.read("spec/support/fixtures/new_public_repo_created_payload.json")
      request_signature = "sha1=" + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha1"), "this_is_not_a_real_secret_token", payload_body)
      headers["HTTP_X_HUB_SIGNATURE"] = request_signature

      expect_any_instance_of(Dcob::Octoclient).to receive(:hookit)
        .with("baxterandthehackers/new-repository", "http://example.org/payload")
        .and_return("Hooked the thing")
      post "/payload", payload_body, headers
      expect(last_response).to be_ok
      expect(last_response).to match("Hooked")
    end

    it "ignores a new private repository" do
      payload_body = File.read("spec/support/fixtures/new_private_repo_created_payload.json")
      request_signature = "sha1=" + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha1"), "this_is_not_a_real_secret_token", payload_body)
      headers["HTTP_X_HUB_SIGNATURE"] = request_signature

      expect_any_instance_of(Dcob::Octoclient).to_not receive(:hookit)
      post "/payload", payload_body, headers
      expect(last_response).to be_ok
      expect(last_response).to match("Nothing to do here.")
    end
  end
end
