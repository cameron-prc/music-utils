class SpotifyWrapper
  SEARCH_FIELDS = "name, items.items(item.id, item.name, item.album(id,name,release_date,total_tracks,artists(id,name)), item.artists(id,name))".freeze

  def initialize(user)
    @client = SpotifyClient.new(user)
  end

  def get_playlist(id)
    response = @client.playlists.find(id, params: { fields: SEARCH_FIELDS })
    response_items = response[:items][:items]

    spotify_track_ids  = response_items.map { |item| item[:item][:id] }
    spotify_album_ids  = response_items.map { |item| item[:item][:album][:id] }
    spotify_artist_ids = response_items.flat_map do |item|
      track_data = item[:item]
      track_data[:artists].map { |artist| artist[:id] } + track_data[:album][:artists].map { |artist| artist[:id] }
    end

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

    playlist_tracks = response_items.map.with_index do |item, position|
      track_data = item[:item]
      album_data = track_data[:album]

      album_artists = album_data[:artists].map.with_index do |artist_data, i|
        artist = known_artists[artist_data[:id]] || build_artist(artist_data)
        AlbumArtist.new(artist: artist, position: i)
      end

      album = known_albums[album_data[:id]] || build_album(album_data).tap do |album|
        album.album_artists = album_artists
      end

      track_artists = track_data[:artists].map.with_index do |artist_data, i|
        artist = known_artists[artist_data[:id]] || build_artist(artist_data)
        TrackArtist.new(artist: artist, position: i)
      end

      track = known_tracks[track_data[:id]] || build_track(track_data, album: album).tap do |t|
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
    Album.new(title: data[:name], release_date: data[:release_date], total_tracks: data[:total_tracks]).tap do |album|
      album.external_ids.build(provider: Providers::SPOTIFY, external_id: data[:id])
    end
  end

  def build_track(data, album:)
    Track.new(title: data[:name], album: album).tap do |track|
      track.external_ids.build(provider: Providers::SPOTIFY, external_id: data[:id])
    end
  end
end
