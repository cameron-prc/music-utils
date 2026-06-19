FactoryBot.define do
  factory :artist_ref do
    sequence(:name) { |n| "Artist #{n}" }
  end
end
