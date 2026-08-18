class SpotifyClient::Tracks
  def initialize(request)
    @request = request
  end

  def find(id, params: nil)
    @request.call(:get, "/v1/tracks/#{id}", params: params)
  end

  def search(query, params: {})
    @request.call(:get, "/v1/search", params: { q: query, type: "track", limit: 5 }.merge(params))
  end
end
