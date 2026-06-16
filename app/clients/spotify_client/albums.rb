class SpotifyClient::Albums
  def initialize(request)
    @request = request
  end

  def find(id, params: nil)
    @request.call(:get, "/albums/#{id}", params: params)
  end
end
