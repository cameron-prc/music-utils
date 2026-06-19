FactoryBot.define do
  factory :external_playlist do
    sequence(:name) { |n| "Playlist #{n}" }
    id { SecureRandom.hex(4) }
    source { nil }

    skip_create
    initialize_with { new(source, id, name) }
  end
end
