require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(username: " DOWNCASEDEXAMPLE ")
    assert_equal("downcasedexample", user.username)
  end
end
