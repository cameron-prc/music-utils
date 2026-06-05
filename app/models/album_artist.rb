class AlbumArtist < ApplicationRecord
  include ArtistPosition

  belongs_to :album
  belongs_to :artist
end
