require "net/http"
require "json"

class SpotifyClient
  BASE_URL = "https://api.spotify.com"

  def initialize(user)
    oauth_token = user.oauth_tokens.find_by!(provider: Providers::SPOTIFY)
    @token      = SpotifyClient::Token.new(oauth_token)
    @token.access_token
  end

  def playlists
    @playlists ||= SpotifyClient::Playlists.new(method(:request))
  end

  def tracks
    @tracks ||= SpotifyClient::Tracks.new(method(:request))
  end

  def artists
    @artists ||= SpotifyClient::Artists.new(method(:request))
  end

  def albums
    @albums ||= SpotifyClient::Albums.new(method(:request))
  end

  def profile
    @profile ||= SpotifyClient::Profile.new(method(:request))
  end

  private

  def request(http_method, path, params: nil, body: nil)
    uri       = URI("#{BASE_URL}#{path}")
    uri.query = URI.encode_www_form(params) if params

    Rails.logger.debug "Spotify request: #{http_method.upcase} #{uri}"

    req = Net::HTTP.const_get(http_method.to_s.capitalize).new(uri)
    req["Authorization"] = "Bearer #{@token.access_token}"

    if body
      req["Content-Type"] = "application/json"
      req.body             = body.to_json
    end

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error "Spotify API error: #{response.code} #{response.message} — #{response.body}"
      raise "Spotify API error: #{response.code} #{response.message}"
    end

    JSON.parse(response.body, symbolize_names: true)
  end
end
