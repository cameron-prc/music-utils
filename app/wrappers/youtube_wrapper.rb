class YoutubeWrapper
  QUOTE_CHARS = /\A["'‘’“”]|["'‘’“”]\z/

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

    ranked = items.sort_by { |item| official?(item.dig(:snippet, :title)) ? 0 : 1 }
    ranked.find { |item|
      parsed = parse_title(item.dig(:snippet, :title))
      matches?(parsed[:title], title)
    }&.dig(:id, :videoId)
  end

  private

  # Parses "Artist - Title (Official Video)" into { artist:, title: }.
  # Does not handle reversed "Title - Artist" format.
  def parse_title(raw_title)
    parts = raw_title.split(" - ", 2)

    if parts.length == 2
      { artist: parts[0].strip, title: clean_title(parts[1]) }
    else
      { artist: nil, title: clean_title(raw_title) }
    end
  end

  def clean_title(raw)
    raw
      .gsub(/\s*[\(\[].*?[\)\]]/, "")
      .sub(/\s*feat\..*\z/i, "")
      .gsub(QUOTE_CHARS, "")
      .strip
  end

  def official?(title)
    title&.match?(/official/i)
  end

  def process_items(items)
    items.filter_map do |item|
      snippet = item[:snippet]
      video_id = snippet.dig(:resourceId, :videoId)
      next unless video_id

      parsed = parse_title(snippet[:title])

      if parsed[:title].blank? || parsed[:artist].blank?
        Rails.logger.warn "skipping unparseable YouTube title: '#{snippet[:title]}'"
        next
      end

      artist_ref = ExternalArtistRef.new(Providers::YOUTUBE, nil, parsed[:artist])
      album_ref  = ExternalAlbumRef.new(Providers::YOUTUBE, nil, nil, nil, [])

      ExternalTrack.new(Providers::YOUTUBE, video_id, parsed[:title], album_ref, [artist_ref])
    end
  end

  def matches?(candidate, target)
    candidate&.downcase == target&.downcase
  end
end
