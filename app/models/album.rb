class Album < ApplicationRecord
  has_many :album_artists
  has_many :artists, through: :album_artists
  has_many :tracks
end
