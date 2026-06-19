FactoryBot.define do
  factory :playlist_track do
    association :playlist
    association :track
    position { 0 }
  end
end
