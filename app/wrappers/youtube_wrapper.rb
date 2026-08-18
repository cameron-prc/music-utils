class YoutubeWrapper
  def initialize(user)
    @client = YoutubeClient.new(user)
  end

  def get_playlist(id)
    details = @client.playlists.find(id)
    snippet = details.dig(:items, 0, :snippet)
    playlist = ExternalPlaylist.new(Providers::YOUTUBE, id, snippet[:title])

    page = @client.playlists.items(id)

    loop do
      playlist.tracks.concat(process_items(page[:items] || []))

      break unless page[:nextPageToken]

      page = @client.playlists.items(id, params: { pageToken: page[:nextPageToken] })
    end

    playlist
  end

  def find_track(title:, artist:, album:)
    query = [title, artist].compact.join(" ")
    response = @client.search.videos(query)
    items = response[:items] || []

    items.find { |item| matches?(item.dig(:snippet, :title), title) }&.dig(:id, :videoId)
  end

  private

  def process_items(items)
    items.filter_map do |item|
      snippet = item[:snippet]
      video_id = snippet.dig(:resourceId, :videoId)
      next unless video_id

      artist_ref = ExternalArtistRef.new(Providers::YOUTUBE, nil, snippet[:videoOwnerChannelTitle])
      album_ref  = ExternalAlbumRef.new(Providers::YOUTUBE, nil, nil, nil, [])

      ExternalTrack.new(Providers::YOUTUBE, video_id, snippet[:title], album_ref, [artist_ref])
    end
  end

  def matches?(candidate, target)
    candidate&.downcase&.include?(target&.downcase)
  end
end
