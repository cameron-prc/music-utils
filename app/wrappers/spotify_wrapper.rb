class SpotifyWrapper
  def initialize(user)
    @client = SpotifyClient.new(user)
  end

  def get_playlist(id)
    search_fields = "name, items.items(item.id, item.name, item.album(id,name,release_date,artists(id,name)), item.artists(id,name))"
    response = @client.playlists.find(id, params: { fields: search_fields })
    response_items = response[:items][:items]

    spotify_artist_ids = response_items.flat_map do |item|
      item[:item][:artists].map { |a| a[:id] } + item[:item][:album][:artists].map { |a| a[:id] }
    end
    spotify_track_ids  = response_items.map { |item| item[:item][:id] }
    spotify_album_ids  = response_items.map { |item| item[:item][:album][:id] }

    known_artists = Artist
      .with_external_id(Providers::SPOTIFY, spotify_artist_ids)
      .includes(:external_ids)
      .index_by { |a| a.external_ids.find(&:spotify?).external_id }

    known_tracks = Track
      .with_external_id(Providers::SPOTIFY, spotify_track_ids)
      .includes(:external_ids)
      .index_by { |t| t.external_ids.find(&:spotify?).external_id }

    known_albums = Album
      .with_external_id(Providers::SPOTIFY, spotify_album_ids)
      .includes(:external_ids)
      .index_by { |a| a.external_ids.find(&:spotify?).external_id }

    playlist_tracks = response_items.each_with_index.map do |item, position|
      album_data = item[:item][:album]
      album_artists = album_data[:artists].each_with_index.map do |artist_data, i|
        artist = known_artists[artist_data[:id]] || build_artist(artist_data)
        AlbumArtist.new(artist: artist, position: i)
      end

      album = known_albums[album_data[:id]] || build_album(album_data).tap do |a|
        a.album_artists = album_artists
      end

      track_artists = item[:item][:artists].each_with_index.map do |artist_data, i|
       # puts artist_data
        artist = known_artists[artist_data[:id]] || build_artist(artist_data)
        #puts artist.inspect
        TrackArtist.new(artist: artist, position: i)
      end
      puts track_artists.inspect

      track = known_tracks[item[:item][:id]] || build_track(item[:item], album: album).tap do |t|
        t.track_artists = track_artists
      end

      PlaylistTrack.new(track: track, position: position)
    end

    Playlist.new(name: response[:name]).tap do |playlist|
      playlist.playlist_tracks = playlist_tracks
    end
  end

  private

  def build_artist(data)
    Artist.new(name: data[:name]).tap do |artist|
      artist.external_ids.build(provider: Providers::SPOTIFY, external_id: data[:id])
    end
  end

  def build_album(data)
    Album.new(title: data[:name], release_date: data[:release_date]).tap do |album|
      album.external_ids.build(provider: Providers::SPOTIFY, external_id: data[:id])
    end
  end

  def build_track(data, album:)
    Track.new(title: data[:name], album: album).tap do |track|
      track.external_ids.build(provider: Providers::SPOTIFY, external_id: data[:id])
    end
  end
end
