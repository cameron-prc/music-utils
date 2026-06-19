require "net/http"
require "json"

class SpotifyClient::Profile
  def initialize(request)
    @request = request
  end

  def me
    @request.call(:get, "/v1/me")
  end
end
