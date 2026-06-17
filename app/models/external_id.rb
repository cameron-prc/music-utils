class ExternalId < ApplicationRecord
  belongs_to :internal, polymorphic: true

  enum :provider, { Spotify: "Spotify" }, validate: true
end
