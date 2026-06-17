class ExternalTrack
  attr_reader :provider
  attr_reader :id
  attr_reader :name
  attr_reader :artist_refs
  attr_reader :album_ref

  def initialize(provider, id, name, album, artists)
    @provider = provider
    @id = id
    @name = name
    @album_ref = album
    @artist_refs = artists
  end
end

