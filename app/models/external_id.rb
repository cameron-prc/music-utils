class ExternalId < ApplicationRecord
  belongs_to :internal, polymorphic: true

  enum :provider, { spotify: "spotify" }, validate: true
end
