module Playlists
  class Hydrate
    def initialize(playlist_id, provider)
      @provider = provider
      @playlist_id = playlist_id
    end

    def call
      playlist = Playlist.find_by(id: @playlist_id).include(:external_ids, :tracks, :artists)
      missing_tracks = playlist.tracks.filter { |track| !track.external_id_for(@provider) }
      missing_artists = playlist.artists.filter { |artist| !artist.external_id_for(@provider) }
    end
  end
end

