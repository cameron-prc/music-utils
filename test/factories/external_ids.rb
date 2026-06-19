FactoryBot.define do
  factory :external_id do
    provider { Providers::SPOTIFY }
    sequence(:external_id) { |n| "spotify_#{n}" }
    association :internal, factory: :artist
  end
end
