class SpotifyClient::Albums
  def initialize(request)
    @request = request
  end

  def find(id, params: nil)
    @request.call(:get, "/v1/albums/#{id}", params: params)
  end
end
