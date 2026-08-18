module ArtistPosition
  extend ActiveSupport::Concern

  def primary_artist?
    position == 0
  end
end
