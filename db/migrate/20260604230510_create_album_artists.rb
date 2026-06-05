class CreateAlbumArtists < ActiveRecord::Migration[8.1]
  def change
    create_table :album_artists do |t|
      t.references :album, null: false, foreign_key: true
      t.references :artist, null: false, foreign_key: true
      t.integer :position

      t.timestamps
    end

    add_index :album_artists, [:album_id, :position], unique: true
  end
end
