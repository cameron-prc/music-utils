class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :oauth_tokens, dependent: :destroy
  normalizes :username, with: ->(e) { e.strip.downcase }
end
