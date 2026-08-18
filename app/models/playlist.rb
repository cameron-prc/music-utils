class Playlist < ApplicationRecord
  include ExternallyIdentifiable

  has_many :external_ids, as: :internal, dependent: :destroy
  has_many :playlist_tracks
  has_many :tracks, through: :playlist_tracks

  def add(track)
    playlist_tracks << PlaylistTrack.new(playlist: self, track: track, position: playlist_tracks.size + 1)
    Rails.logger.info "adding #{track.title}"
  end

  def clear()
    tracks.clear
  end
end
