FactoryBot.define do
  factory :external_track do
    sequence(:name) { |n| "Track #{n}" }
    id { SecureRandom.hex(4) }
    provider { nil }
    album_ref { nil }
    artist_refs { [] }

    skip_create
    initialize_with { new(provider, id, name, album_ref, artist_refs) }
  end
end
