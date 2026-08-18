require "net/http"
require "json"

class YoutubeClient::Authorisation
  TOKEN_URL = "https://oauth2.googleapis.com/token"
  AUTH_URL  = "https://accounts.google.com/o/oauth2/v2/auth"
  SCOPES    = %w[https://www.googleapis.com/auth/youtube].freeze

  class << self
    def credentials
      Rails.application.credentials.youtube
    end

    def build_authorisation_url(state:)
      params = {
        client_id:     credentials.client_id,
        response_type: "code",
        redirect_uri:  credentials.redirect_uri,
        scope:         SCOPES.join(" "),
        state:         state,
        access_type:   "offline",
        prompt:        "consent"
      }
      "#{AUTH_URL}?#{URI.encode_www_form(params)}"
    end

    def request_access_tokens(code)
      body = post_token(
        grant_type:    "authorization_code",
        code:          code,
        redirect_uri:  credentials.redirect_uri,
        client_id:     credentials.client_id,
        client_secret: credentials.client_secret
      )
      {
        access_token:  body[:access_token],
        refresh_token: body[:refresh_token],
        expires_in:    body[:expires_in]
      }
    end

    def refresh!(oauth_token)
      body = post_token(
        grant_type:    "refresh_token",
        refresh_token: oauth_token.refresh_token,
        client_id:     credentials.client_id,
        client_secret: credentials.client_secret
      )
      oauth_token.update!(access_token: body[:access_token], expires_at: Time.now + body[:expires_in])
    end

    private

    def post_token(params)
      uri     = URI(TOKEN_URL)
      request = Net::HTTP::Post.new(uri)
      request.set_form_data(params)
      Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| JSON.parse(http.request(request).body, symbolize_names: true) }
    end
  end
end
