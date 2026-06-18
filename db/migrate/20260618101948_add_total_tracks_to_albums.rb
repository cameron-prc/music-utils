class AddTotalTracksToAlbums < ActiveRecord::Migration[8.1]
  def change
    add_column :albums, :total_tracks, :integer, null: false
  end
end
