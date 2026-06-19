FactoryBot.define do
  factory :track_artist do
    association :track
    association :artist, factory: :artist_ref
    position { 0 }
  end
end
