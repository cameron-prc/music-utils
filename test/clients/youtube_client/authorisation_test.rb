require "test_helper"

class YoutubeClient::AuthorisationTest < ActiveSupport::TestCase
  test "build_authorisation_url includes required oauth params" do
    fake_credentials = Struct.new(:client_id, :client_secret, :redirect_uri).new(
      "test_client_id",
      "test_client_secret",
      "http://localhost:3000/oauth/youtube/callback"
    )

    YoutubeClient::Authorisation.define_singleton_method(:credentials) { fake_credentials }

    url = YoutubeClient::Authorisation.build_authorisation_url(state: "teststate123")

    assert_includes url, "https://accounts.google.com/o/oauth2/v2/auth"
    assert_includes url, "client_id=test_client_id"
    assert_includes url, "response_type=code"
    assert_includes url, "state=teststate123"
    assert_includes url, "access_type=offline"
    assert_includes url, "prompt=consent"
    assert_includes url, URI.encode_www_form_component("https://www.googleapis.com/auth/youtube")
  ensure
    YoutubeClient::Authorisation.define_singleton_method(:credentials) { Rails.application.credentials.youtube }
  end
end
