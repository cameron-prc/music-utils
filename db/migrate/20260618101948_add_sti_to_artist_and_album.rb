class AddStiToArtistAndAlbum < ActiveRecord::Migration[8.1]
  def change
    add_column :artists, :type, :string, null: false
    add_column :artists, :last_synced_at, :date
    add_column :artists, :last_synced_provider, :string
    add_column :albums, :type, :string, null: false
    add_column :albums, :last_synced_at, :date
    add_column :albums, :last_synced_provider, :string
  end
end
