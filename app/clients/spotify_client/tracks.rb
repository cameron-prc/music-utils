class SpotifyClient::Tracks
  def initialize(request)
    @request = request
  end

  def find(id, params: nil)
    @request.call(:get, "/v1/tracks/#{id}", params: params)
  end
end
