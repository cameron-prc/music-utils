class Artist < ApplicationRecord
  has_many :external_ids, as: :internal, dependent: :destroy
  has_many :track_artists
  has_many :tracks, through: :track_artists
end
