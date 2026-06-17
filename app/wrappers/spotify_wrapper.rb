class SpotifyWrapper
  PLAYLIST_DETAILS_FIELDS = "name, items.total".freeze
  PLAYLIST_TRACKS_FIELDS = "offset, next, items(item.id, item.name, item.album(id,name,release_date,total_tracks,artists(id,name)), item.artists(id,name))".freeze

  def initialize(user)
   @client = SpotifyClient.new(user)
  end

  def get_playlist(id)
    playlist_details = @client.playlists.find(id, params: { fields: PLAYLIST_DETAILS_FIELDS })
    tracks_page = @client.playlists.tracks(id, params: { fields: PLAYLIST_TRACKS_FIELDS })

    playlist = ExternalPlaylist.new(Providers::SPOTIFY, playlist_details[:id], playlist_details[:name])

    loop.with_index do |index|
      playlist.tracks.concat(process_tracks_page(tracks_page[:items]))
      
      break unless tracks_page[:next]
      
      tracks_page = @client.playlists.next(tracks_page[:next])
    end
  end

  def process_tracks_page(items)
    items.map.with do |item|
      track_data = item[:item]
      album_data = track_data[:album]

      album_artist_refs = album_data[:artists].map do |artist_data|
        build_artist(artist_data)
      end

      track_artist_refs = track_data[:artists].map do |artist_data|
        build_artist(artist_data)
      end

      album_ref = ExternalAlbumRef.new(Providers::SPOTIFY, album_data[:id], album_data[:name], album_data[:release_date], album_artist_refs)

      ExternalTrack.new(Providers::SPOTIFY, track_data[:id], track_data[:name], album_ref, track_artist_refs)
    end
  end

  private

  def build_artist(data)
    ExternalArtistRef.new(Providers::SPOTIFY, data[:id], data[:name])
  end
end
