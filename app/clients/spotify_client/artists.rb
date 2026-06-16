class SpotifyClient::Artists
  def initialize(request)
    @request = request
  end

  def find(id, params: nil)
    @request.call(:get, "/artists/#{id}", params: params)
  end
end
