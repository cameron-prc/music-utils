class SpotifyClient::Artists
  def initialize(request)
    @request = request
  end

  def find(id, params: nil)
    @request.call(:get, "/v1/artists/#{id}", params: params)
  end
end
