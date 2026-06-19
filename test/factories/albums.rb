FactoryBot.define do
  factory :album do
    sequence(:title) { |n| "Album #{n}" }
    release_date { "2020-01-01" }
    total_tracks { 10 }
  end
end
