class YoutubeClient::Search
  def initialize(request)
    @request = request
  end

  def videos(query, params: {})
    @request.call(:get, "/search", params: { part: "snippet", type: "video", videoCategoryId: 10, q: query, maxResults: 5 }.merge(params))
  end
end
