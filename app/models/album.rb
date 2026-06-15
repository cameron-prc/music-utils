class Album < ApplicationRecord
  has_many :external_ids, as: :internal, dependent: :destroy
  has_many :album_artists
  has_many :artists, through: :album_artists
  has_many :tracks
end
