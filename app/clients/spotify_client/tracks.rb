class SpotifyClient::Tracks
  def initialize(request)
    @request = request
  end

  def find(id, params: nil)
    @request.call(:get, "/tracks/#{id}", params: params)
  end
end
