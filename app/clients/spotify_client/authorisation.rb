require "net/http"
require "base64"
require "json"

class SpotifyClient::Authorisation
  TOKEN_URL = "https://accounts.spotify.com/api/token"
  AUTH_URL  = "https://accounts.spotify.com/authorize"
  SCOPES = %w[
    playlist-read-private
    playlist-read-collaborative
    playlist-modify-public
    playlist-modify-private
  ].freeze

  class << self
    def credentials
      Rails.application.credentials.spotify
    end

    def build_authorisation_url(state:)
      params = {
        client_id:     credentials.client_id,
        response_type: "code",
        redirect_uri:  credentials.redirect_uri,
        scope:         SCOPES.join(" "),
        state:         state
      }
      "#{AUTH_URL}?#{URI.encode_www_form(params)}"
    end

    def request_access_tokens(code)
      body = post_token(grant_type: "authorization_code", code: code, redirect_uri: credentials.redirect_uri)
      {
        access_token:  body[:access_token],
        refresh_token: body[:refresh_token],
        expires_in:    body[:expires_in]
      }
    end

    def refresh!(oauth_token)
      body = post_token(grant_type: "refresh_token", refresh_token: oauth_token.refresh_token)
      oauth_token.update!(access_token: body[:access_token], expires_at: Time.now + body[:expires_in])
    end

    private

    def post_token(params)
      uri     = URI(TOKEN_URL)
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Basic #{Base64.strict_encode64("#{credentials.client_id}:#{credentials.client_secret}")}"
      request.set_form_data(params)
      Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| JSON.parse(http.request(request).body, symbolize_names: true) }
    end
  end
end
