class Artist < ApplicationRecord
  include ExternallyIdentifiable

  has_many :external_ids, as: :internal, dependent: :destroy
  has_many :track_artists
  has_many :tracks, through: :track_artists

  def externally_known_to
    external_ids.pluck(:provider)
  end
end
