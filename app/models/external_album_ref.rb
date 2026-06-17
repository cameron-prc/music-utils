class ExternalAlbumRef
  attr_reader :provider
  attr_reader :id
  attr_reader :name
  attr_reader :artist_refs
  attr_reader :release_date

  def initialize(provider, id, name, release_date, artists)
    @provider = provider
    @id = id
    @name = name
    @release_date = release_date
    @artist_refs = artists
  end
end
