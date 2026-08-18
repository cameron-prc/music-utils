class ExternalPlaylist
  attr_reader :provider
  attr_reader :id
  attr_reader :name
  attr_accessor :tracks

  def initialize(provider, id, name)
    @provider = provider
    @id = id
    @name = name
    @tracks = []
  end
end

