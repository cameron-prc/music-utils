require "net/http"
require "json"

class YoutubeClient
  BASE_URL = "https://www.googleapis.com/youtube/v3"

  def initialize(user)
    oauth_token = user.oauth_tokens.find_by!(provider: Providers::YOUTUBE)
    @token      = YoutubeClient::Token.new(oauth_token)
  end

  def playlists
    @playlists ||= YoutubeClient::Playlists.new(method(:request))
  end

  def search
    @search ||= YoutubeClient::Search.new(method(:request))
  end

  private

  def request(http_method, path, params: nil, body: nil)
    uri       = URI("#{BASE_URL}#{path}")
    uri.query = URI.encode_www_form(params) if params

    Rails.logger.debug "YouTube request: #{http_method.upcase} #{uri}"

    req = Net::HTTP.const_get(http_method.to_s.capitalize).new(uri)
    req["Authorization"] = "Bearer #{@token.access_token}"

    if body
      req["Content-Type"] = "application/json"
      req.body             = body.to_json
    end

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error "YouTube API error: #{response.code} #{response.message} — #{response.body}"
      raise "YouTube API error: #{response.code} #{response.message}"
    end

    JSON.parse(response.body, symbolize_names: true)
  end
end
