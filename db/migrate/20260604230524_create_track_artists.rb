class CreateTrackArtists < ActiveRecord::Migration[8.1]
  def change
    create_table :track_artists do |t|
      t.references :track, null: false, foreign_key: true
      t.references :artist, null: false, foreign_key: true
      t.integer :position

      t.timestamps
    end
  end
end
