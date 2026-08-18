class ExternalId < ApplicationRecord
  belongs_to :internal, polymorphic: true

  enum :provider, { Spotify: "Spotify", YouTube: "YouTube" }, validate: true
end
