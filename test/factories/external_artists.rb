FactoryBot.define do
  factory :external_artist_ref do
    sequence(:name) { |n| "Artist #{n}" }
    id { SecureRandom.hex(4) }
    provider { nil }

    skip_create
    initialize_with { new(provider, id, name) }
  end
end
