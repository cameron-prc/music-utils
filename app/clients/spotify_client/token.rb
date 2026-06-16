class SpotifyClient::Token
  def initialize(oauth_token)
    @oauth_token = oauth_token
  end

  def access_token
    SpotifyClient::Authorisation.refresh!(@oauth_token) if @oauth_token.expires_at <= Time.now
    @oauth_token.access_token
  end
end
