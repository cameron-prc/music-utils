class Track < ApplicationRecord
  belongs_to :album
  has_many :track_artists
  has_many :artists, through: :track_artists
end
