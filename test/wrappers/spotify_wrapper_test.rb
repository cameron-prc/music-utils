require "test_helper"

class SpotifyWrapperTest < ActiveSupport::TestCase
  setup do
    @wrapper = SpotifyWrapper.allocate
  end

  test "find_track returns id when exact title matches" do
    stub_search([
      { id: "abc123", name: "Doxy" },
      { id: "other", name: "Doxy (Live)" }
    ])

    result = @wrapper.find_track(title: "Doxy", artist: "Miles Davis", album: "Bags' Groove")

    assert_equal "abc123", result
  end

  test "find_track matches case-insensitively" do
    stub_search([{ id: "abc123", name: "doxy" }])

    result = @wrapper.find_track(title: "Doxy", artist: "Miles Davis", album: nil)

    assert_equal "abc123", result
  end

  test "find_track returns nil when no title matches" do
    stub_search([
      { id: "wrong1", name: "Foxy" },
      { id: "wrong2", name: "Boxy" }
    ])

    result = @wrapper.find_track(title: "Doxy", artist: "Miles Davis", album: nil)

    assert_nil result
  end

  test "find_track returns nil when search returns no results" do
    stub_search([])

    result = @wrapper.find_track(title: "Nonexistent Track", artist: "Nobody", album: nil)

    assert_nil result
  end

  test "find_track builds query with track and artist fields" do
    tracks = stub_search([])

    @wrapper.find_track(title: "Doxy", artist: "Miles Davis", album: nil)

    assert_equal "track:Doxy artist:Miles Davis", tracks.last_query
  end

  test "find_track includes album field when present" do
    tracks = stub_search([])

    @wrapper.find_track(title: "Doxy", artist: "Miles Davis", album: "Bags' Groove")

    assert_equal "track:Doxy artist:Miles Davis album:Bags' Groove", tracks.last_query
  end

  test "find_track omits artist field when nil" do
    tracks = stub_search([])

    @wrapper.find_track(title: "Doxy", artist: nil, album: nil)

    assert_equal "track:Doxy", tracks.last_query
  end

  private

  def stub_search(items)
    tracks = StubTracks.new(items)
    client = Struct.new(:tracks).new(tracks)
    @wrapper.instance_variable_set(:@client, client)
    tracks
  end

  class StubTracks
    attr_reader :last_query

    def initialize(items)
      @items = items
    end

    def search(query, params: {})
      @last_query = query
      { tracks: { items: @items } }
    end
  end
end
