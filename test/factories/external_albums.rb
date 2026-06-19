FactoryBot.define do
  factory :external_album_ref do
    sequence(:name) { |n| "Album #{n}" }
    id { SecureRandom.hex(4) }
    release_date { "2020-01-01" }
    provider { nil }
    artist_refs { [] }

    skip_create
    initialize_with { new(provider, id, name, release_date, artist_refs) }
  end
end
