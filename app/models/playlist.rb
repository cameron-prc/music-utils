class Playlist < ApplicationRecord
  include ExternallyIdentifiable

  has_many :external_ids, as: :internal, dependent: :destroy
  has_many :playlist_tracks
  has_many :tracks, through: :playlist_tracks
end
