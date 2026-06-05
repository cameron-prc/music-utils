module ArtistPosition
  extend ActiveSupport::Concern

  def primaryArtist?
    position == 0
  end
end
