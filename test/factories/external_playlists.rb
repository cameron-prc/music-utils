FactoryBot.define do
  factory :external_playlist do
    sequence(:name) { |n| "Playlist #{n}" }
    id { SecureRandom.hex(4) }
    provider { nil }

    skip_create
    initialize_with { new(provider, id, name) }
  end
end
