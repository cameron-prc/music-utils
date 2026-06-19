FactoryBot.define do
  factory :track_artist do
    association :track
    association :artist
    position { 0 }
  end
end
