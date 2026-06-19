module Playlists
  class Import
    WRAPPERS = {
      Providers::SPOTIFY => SpotifyWrapper
    }

    def initialize(user, playlist_id, provider)
      @user        = user
      @playlist_id = playlist_id
      @provider    = provider
    end

    def call
      @playlist = wrapper.get_playlist(@playlist_id)

      ActiveRecord::Base.transaction do
        new_artists.each(&:save!)
        new_albums.each(&:save!)
        new_tracks.each(&:save!)
        persist_playlist
      end
    end

    private

    def wrapper
      WRAPPERS.fetch(@provider).new(@user)
    end

    def tracks
      @tracks ||= @playlist.playlist_tracks.map(&:track)
    end

    def new_artists
      tracks.flat_map { |t| t.track_artists.map(&:artist) + t.album.album_artists.map(&:artist) }
            .reject(&:persisted?)
            .uniq
    end

    def new_albums
      tracks.map(&:album).reject(&:persisted?).uniq
    end

    def new_tracks
      tracks.reject(&:persisted?)
    end

    def persist_playlist
      record = Playlist.find_by_external_id(provider: @provider, external_id: @playlist_id) || @playlist

      record.assign_attributes(name: @playlist.name)
      record.playlist_tracks.destroy_all if record.persisted?
      record.playlist_tracks = @playlist.playlist_tracks
      record.external_ids.build(provider: @provider, external_id: @playlist_id) unless record.persisted?
      record.save!
    end
  end
end
