module Playlists
  class Hydrate
    WRAPPERS = {
      Providers::SPOTIFY => SpotifyWrapper
    }

    def initialize(user, playlist_id, provider)
      @user        = user
      @playlist_id = playlist_id
      @provider    = provider
    end

    def call
      playlist = Playlist.find(@playlist_id)
      tracks   = playlist.tracks.includes(:external_ids, :artists)

      unmatched_tracks = tracks.reject { |track| track.external_id_for(@provider) }

      Rails.logger.info "hydrating #{unmatched_tracks.size} of #{tracks.size} tracks for #{@provider}"

      results = { resolved: 0, unresolved: 0 }

      unmatched_tracks.each do |track|
        external_id = wrapper.find_track(
          title:  track.title,
          artist: track.artists.first&.name,
          album:  track.album&.title
        )

        unless external_id
          Rails.logger.info "no match for '#{track.title}' on #{@provider}"
          results[:unresolved] += 1
          next
        end

        track.external_ids.create!(provider: @provider, external_id: external_id)
        results[:resolved] += 1
      end

      Rails.logger.info "hydration complete: #{results[:resolved]} resolved, #{results[:unresolved]} unresolved"

      results
    end

    private

    def wrapper
      @wrapper ||= WRAPPERS.fetch(@provider).new(@user)
    end
  end
end
