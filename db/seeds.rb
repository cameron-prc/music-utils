require 'securerandom'

puts "Seeding database..."

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# If there are no users, generate a default user with a random password
# Good enough for development, should find a better way of doing first load stuff though
if !User.none?
  default_user = User.new(username: "admin")

  password = SecureRandom.alphanumeric(8)
  default_user.password = password
  default_user.password_confirmation = password
 
  if default_user.save
    puts "Default user created"
    puts "username: %{default_user.username}"
    puts "password: %{password}"
  else
    puts "❌ Failed to create default user: #{default_user.errors.full_messages.join(', ')}"
  end
end
