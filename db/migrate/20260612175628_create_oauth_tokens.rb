class CreateOauthTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :oauth_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :refresh_token, null: false
      t.string :access_token, null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :oauth_tokens, [:user_id, :provider], unique: true
  end
end
