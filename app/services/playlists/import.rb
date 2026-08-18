module Playlists
  class Import
    WRAPPERS = {
      Providers::SPOTIFY => SpotifyWrapper,
      Providers::YOUTUBE => YoutubeWrapper
    }

    def initialize(user, playlist_id, provider)
      @user          = user
      @playlist_id   = playlist_id
      @provider      = provider
      @known_artists = []
      @known_albums  = []
      @known_tracks  = []
    end

    def call
      external_playlist = wrapper.get_playlist(@playlist_id)

      track_ids  = external_playlist.tracks.map(&:id).uniq
      album_ids  = external_playlist.tracks.map { |track| track.album_ref.id }.uniq
      artist_ids = external_playlist.tracks.flat_map do |track|
        track.artist_refs.map{ |artist| artist.id }.concat(track.album_ref.artist_refs.map { |artist| artist.id})
      end.uniq

      @known_artists = Artist.with_external_id(@provider, artist_ids).includes(:external_ids).to_a
      @known_albums  = Album.with_external_id(@provider, album_ids).includes(:external_ids).to_a
      @known_tracks  = Track.with_external_id(@provider, track_ids).includes(:external_ids).to_a

      ActiveRecord::Base.transaction do
        @playlist = find_or_create_playlist(external_playlist)

        if @playlist.name != external_playlist.name
          Rails.logger.info "updating playlist name from '#{@playlist.name}' to '#{external_playlist.name}'"
          @playlist.name = external_playlist.name
        end

        @playlist.clear

        external_playlist.tracks.each do |external_track|
          track = find_or_create_track(external_track)
          @playlist.add(track)
        end

        @playlist.save!
      end
    end

    private

    def find_or_create_playlist(external_playlist)
      existing_playlist = Playlist.find_by_external_id(Providers::SPOTIFY, external_playlist.id)

      return existing_playlist if existing_playlist

      Rails.logger.info "building new playlist with id #{external_playlist.id}"
      new_playlist = Playlist.new(name: external_playlist.name)
      new_playlist.external_ids << ExternalId.new(provider: Providers::SPOTIFY, external_id: external_playlist.id)

      new_playlist
    end

    def find_or_create_artist(external_artist)
      known_artist = find_in(@known_artists, external_artist.provider, external_artist.id)
      return known_artist if known_artist

      external_id = ExternalId.build(provider: external_artist.provider, external_id: external_artist.id)
      artist      = ArtistRef.create!(name: external_artist.name, external_ids: [external_id])

      @known_artists << artist

      artist
    end

    def find_or_create_album(external_album)
      known_album = find_in(@known_albums, external_album.provider, external_album.id)

      return known_album if known_album

      artists     = external_album.artist_refs.map { |external_artist_ref| find_or_create_artist(external_artist_ref) }
      external_id = ExternalId.build(provider: external_album.provider, external_id: external_album.id)
      album       = AlbumRef.create!(title: external_album.name, artists: artists, external_ids: [external_id])

      @known_albums << album

      album
    end

    def find_or_create_track(external_track)
      known_track = find_in(@known_tracks, external_track.provider, external_track.id)
      return known_track if known_track

      artists     = external_track.artist_refs.map { |external_artist_ref| find_or_create_artist(external_artist_ref) }
      album       = external_track.album_ref.then { |external_album_ref| find_or_create_album(external_album_ref) }
      external_id = ExternalId.build(provider: external_track.provider, external_id: external_track.id)

      track = Track.create(title: external_track.name, artists: artists, album: album, external_ids: [external_id])

      @known_tracks << track

      track
    end


    def find_in(collection, provider, external_id)
      collection.find { |r| r.external_ids.detect { |e| e.provider == provider && e.external_id == external_id } }
    end

    def wrapper
      WRAPPERS.fetch(@provider).new(@user)
    end
  end
end
