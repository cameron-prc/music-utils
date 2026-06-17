class ExternalId < ApplicationRecord
  belongs_to :internal, polymorphic: true

  enum :provider, { spotify: "Spotify" }, validate: true
end
