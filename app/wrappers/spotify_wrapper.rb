class SpotifyWrapper
  PLAYLIST_DETAILS_FIELDS = "name, items.total".freeze
  PLAYLIST_TRACKS_FIELDS = "offset, next, items(item.id, item.name, item.album(id,name,release_date,total_tracks,artists(id,name)), item.artists(id,name))".freeze


  def initialize(user)
   @known_artists = {}
   @known_albums = {}
   @known_tracks = {}
   @playlist_tracks = []

   @client = SpotifyClient.new(user)
  end

  def get_playlist(id)
    playlist_details = @client.playlists.find(id, params: { fields: PLAYLIST_DETAILS_FIELDS })
    tracks_page = @client.playlists.tracks(id, params: { fields: PLAYLIST_TRACKS_FIELDS })

    loop.with_index do |index|
      process_tracks_page(tracks_page[:items], tracks_page[:offset])
      
      break unless tracks_page[:next]
      
      tracks_page = @client.playlists.next(tracks_page[:next])
    end

    Playlist.new(name: playlist_details[:name]).tap do |playlist|
      puts @playlist_tracks.count
      playlist.playlist_tracks = @playlist_tracks
    end
  end

  def process_tracks_page(items, offset)
    spotify_track_ids  = items.map { |item| item[:item][:id] }
    spotify_album_ids  = items.map { |item| item[:item][:album][:id] }
    spotify_artist_ids = items.flat_map do |item|
      track_data = item[:item]
      track_data[:artists].map { |artist| artist[:id] } + track_data[:album][:artists].map { |artist| artist[:id] }
    end

    unprocessed_artists = spotify_artist_ids - @known_artists.keys
    unprocessed_albums  = spotify_album_ids  - @known_albums.keys
    unprocessed_tracks  = spotify_track_ids  - @known_tracks.keys

    @known_artists.merge!(Artist.with_external_id(Providers::SPOTIFY, unprocessed_artists).includes(:external_ids).index_by { |a| a.external_id_for(Providers::SPOTIFY) })
    @known_albums.merge!(Album.with_external_id(Providers::SPOTIFY, unprocessed_albums).includes(:external_ids).index_by { |a| a.external_id_for(Providers::SPOTIFY) })
    @known_tracks.merge!(Track.with_external_id(Providers::SPOTIFY, unprocessed_tracks).includes(:external_ids).index_by { |t| t.external_id_for(Providers::SPOTIFY) })

    @playlist_tracks.concat(items.map.with_index do |item, track_index|
      track_data = item[:item]
      album_data = track_data[:album]

      album_artists = album_data[:artists].map.with_index do |artist_data, i|
        artist = @known_artists[artist_data[:id]] || build_artist(artist_data)
        AlbumArtist.new(artist: artist, position: i)
      end

      album = @known_albums[album_data[:id]] || build_album(album_data).tap do |album|
        album.album_artists = album_artists
      end

      track_artists = track_data[:artists].map.with_index do |artist_data, i|
        artist = @known_artists[artist_data[:id]] || build_artist(artist_data)
        TrackArtist.new(artist: artist, position: i + 1)
      end

      track = @known_tracks[track_data[:id]] || build_track(track_data, album: album).tap do |t|
        t.track_artists = track_artists
      end

      PlaylistTrack.new(track: track, position: track_index + 1 + offset)
    end)
  end

  private

  def build_artist(data)
    artist = Artist.new(name: data[:name]).tap do |artist|
      artist.external_ids.build(provider: Providers::SPOTIFY, external_id: data[:id])
    end

    @known_artists[data[:id]] = artist

    artist
  end

  def build_album(data)
    album = Album.new(title: data[:name], release_date: data[:release_date], total_tracks: data[:total_tracks]).tap do |album|
      album.external_ids.build(provider: Providers::SPOTIFY, external_id: data[:id])
    end

    @known_albums[data[:id]] = album

    album
  end

  def build_track(data, album:)
    track = Track.new(title: data[:name], album: album).tap do |track|
      track.external_ids.build(provider: Providers::SPOTIFY, external_id: data[:id])
    end

    @known_tracks[data[:id]] = track

    track
  end
end
