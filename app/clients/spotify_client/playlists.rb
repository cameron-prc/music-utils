class SpotifyClient::Playlists
  include SpotifyClient::Nextable

  def initialize(request)
    @request = request
  end

  def find(id, params: nil)
    @request.call(:get, "/v1/playlists/#{id}", params: params)
  end

  def tracks(id, params: nil)
    @request.call(:get, "/v1/playlists/#{id}/tracks", params: params)
  end
end
