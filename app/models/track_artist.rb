class TrackArtist < ApplicationRecord
  include ArtistPosition

  belongs_to :track
  belongs_to :artist
end
