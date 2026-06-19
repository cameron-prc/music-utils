FactoryBot.define do
  factory :track do
    sequence(:title) { |n| "Track #{n}" }
    association :album, factory: :album_ref
  end
end
