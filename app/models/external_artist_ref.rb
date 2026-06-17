class ExternalArtistRef
  attr_accessor :provider
  attr_reader :id
  attr_accessor :name

  def initialize(provider, id, name)
    @provider = provider
    @id = id
    @name = name
  end
end

