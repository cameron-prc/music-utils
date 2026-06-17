class Artist < ApplicationRecord
  include ExternallyIdentifiable

  has_many :external_ids, as: :internal, dependent: :destroy
  has_many :album_artists
  has_many :albums, through: :album_artists
  has_many :track_artists
  has_many :tracks, through: :track_artists

  def externally_known_to
    external_ids?.map { |external_id| external_id.provider }
  end
end
