class YoutubeClient::Playlists
  def initialize(request)
    @request = request
  end

  def find(id)
    @request.call(:get, "/playlists", params: { part: "snippet", id: id })
  end

  def items(playlist_id, params: {})
    @request.call(:get, "/playlistItems", params: { part: "snippet", playlistId: playlist_id, maxResults: 50 }.merge(params))
  end

  def insert(body:)
    @request.call(:post, "/playlists", params: { part: "snippet,status" }, body: body)
  end

  def insert_item(body:)
    @request.call(:post, "/playlistItems", params: { part: "snippet" }, body: body)
  end
end
