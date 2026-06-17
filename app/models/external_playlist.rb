class ExternalPlaylist
  attr_reader :source
  attr_reader :id
  attr_reader :name
  attr_accessor :tracks

  def initialize(source, id, name)
    @source = source
    @id = id
    @name = name
    @tracks = []
  end
end

