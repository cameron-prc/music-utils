class OauthToken < ApplicationRecord
  belongs_to :user

  encrypts :refresh_token, :access_token
  encrypts :access_token, :access_token
end
