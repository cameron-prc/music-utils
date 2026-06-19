FactoryBot.define do
  factory :album_ref do
    sequence(:title) { |n| "Album #{n}" }
    release_date { "2020-01-01" }
  end
end
