FactoryBot.define do
  factory :album_artist do
    association :album
    association :artist
    position { 0 }
  end
end
