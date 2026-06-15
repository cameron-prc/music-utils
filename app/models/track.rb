class Track < ApplicationRecord
  has_many :external_ids, as: :internal, dependent: :destroy
  belongs_to :album
  has_many :track_artists
  has_many :artists, through: :track_artists
end
