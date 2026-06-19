FactoryBot.define do
  factory :album_artist do
    association :album, factory: :album_ref
    association :artist, factory: :artist_ref
    position { 0 }
  end
end
