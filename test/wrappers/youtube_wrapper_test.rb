require "test_helper"

class YoutubeWrapperTest < ActiveSupport::TestCase
  setup do
    @wrapper = YoutubeWrapper.allocate
  end

  # -- parse_title: separator --

  test "parse_title splits on artist - title" do
    assert_parsed "Miles Davis - So What", artist: "Miles Davis", title: "So What"
  end

  test "parse_title splits on first separator only" do
    assert_parsed "AC/DC - Back In Black - Remastered", artist: "AC/DC", title: "Back In Black - Remastered"
  end

  test "parse_title falls back to full string when no separator" do
    assert_parsed "So What", artist: nil, title: "So What"
  end

  # -- parse_title: parenthetical stripping --

  test "parse_title strips parenthetical suffix" do
    assert_parsed "Artist - Track (Official Audio)", artist: "Artist", title: "Track"
  end

  test "parse_title strips square bracket suffix" do
    assert_parsed "Artist - Track [Official Video]", artist: "Artist", title: "Track"
  end

  test "parse_title strips multiple parenthetical groups" do
    assert_parsed "Artist - Track (Official Video) (Remastered)", artist: "Artist", title: "Track"
  end

  test "parse_title strips mixed brackets and parens" do
    assert_parsed "Radiohead - Creep [Official Video] (Remastered)", artist: "Radiohead", title: "Creep"
  end

  test "parse_title strips featuring in parentheses" do
    assert_parsed "Drake - One Dance (feat. Wizkid & Kyla)", artist: "Drake", title: "One Dance"
  end

  test "parse_title strips bracketed featuring from title" do
    assert_parsed "Drake - One Dance (feat. Wizkid & Kyla)",
      artist: "Drake", title: "One Dance"
  end

  test "parse_title strips unbracketed feat. and everything after it" do
    assert_parsed "Drake - One Dance feat. Wizkid & Kyla",
      artist: "Drake", title: "One Dance"
  end

  test "parse_title returns nil artist when no separator" do
    assert_parsed "So What (Official Audio)", artist: nil, title: "So What"
  end

  # -- parse_title: quote stripping --

  test "parse_title strips double quotes" do
    assert_parsed 'Kendrick Lamar - "HUMBLE."', artist: "Kendrick Lamar", title: "HUMBLE."
  end

  test "parse_title strips single quotes" do
    assert_parsed "Artist - 'Track Name'", artist: "Artist", title: "Track Name"
  end

  test "parse_title strips smart double quotes" do
    assert_parsed "Artist - “Track Name”", artist: "Artist", title: "Track Name"
  end

  test "parse_title strips quotes and parentheticals together" do
    assert_parsed 'Artist - "Track Name" (Official Video)', artist: "Artist", title: "Track Name"
  end

  # -- parse_title: skip unparseable --

  test "get_playlist skips items with empty title after cleaning" do
    stub_playlist_import([
      { title: "(Official Audio)", channel: "SomeChannel", id: "v1" },
      { title: "Artist - Real Track", channel: "Ch", id: "v2" }
    ])

    result = @wrapper.get_playlist("PL1")

    assert_equal 1, result.tracks.size
    assert_equal "Real Track", result.tracks[0].name
  end

  test "get_playlist skips items with no separator" do
    stub_playlist_import([
      { title: "So What", channel: "Miles Davis", id: "v1" },
      { title: "Artist - Good Track", channel: "Ch", id: "v2" }
    ])

    result = @wrapper.get_playlist("PL1")

    assert_equal 1, result.tracks.size
    assert_equal "Good Track", result.tracks[0].name
  end

  # -- get_playlist --

  test "get_playlist uses parsed artist and title" do
    stub_playlist_import([
      { title: "Miles Davis - So What (Official Audio)", channel: "MilesVEVO", id: "vid1" }
    ])

    result = @wrapper.get_playlist("PL123")

    assert_equal "So What", result.tracks[0].name
    assert_equal "Miles Davis", result.tracks[0].artist_refs[0].name
  end

  test "get_playlist paginates through multiple pages" do
    stub_client(
      find_response: { items: [{ snippet: { title: "Big Playlist" } }] },
      items_responses: [
        { items: [{ snippet: { title: "Artist - Track 1", videoOwnerChannelTitle: "Ch1", resourceId: { videoId: "v1" } } }],
          nextPageToken: "page2token" },
        { items: [{ snippet: { title: "Artist - Track 2", videoOwnerChannelTitle: "Ch2", resourceId: { videoId: "v2" } } }] }
      ]
    )

    result = @wrapper.get_playlist("PLbig")

    assert_equal 2, result.tracks.size
    assert_equal "Track 1", result.tracks[0].name
    assert_equal "Track 2", result.tracks[1].name
  end

  # -- find_track --

  test "find_track returns video id when parsed title matches" do
    stub_client(
      search_response: { items: [
        { id: { videoId: "match1" }, snippet: { title: "Miles Davis - Doxy (Official Audio)" } }
      ] }
    )

    result = @wrapper.find_track(title: "Doxy", artist: "Miles Davis", album: nil)

    assert_equal "match1", result
  end

  test "find_track matches case-insensitively" do
    stub_client(
      search_response: { items: [{ id: { videoId: "vid1" }, snippet: { title: "Miles Davis - DOXY" } }] }
    )

    result = @wrapper.find_track(title: "Doxy", artist: "Miles Davis", album: nil)

    assert_equal "vid1", result
  end

  test "find_track prefers official results" do
    stub_client(
      search_response: { items: [
        { id: { videoId: "fan" }, snippet: { title: "Miles Davis - Doxy (Fan Upload)" } },
        { id: { videoId: "official" }, snippet: { title: "Miles Davis - Doxy (Official Audio)" } }
      ] }
    )

    result = @wrapper.find_track(title: "Doxy", artist: "Miles Davis", album: nil)

    assert_equal "official", result
  end

  test "find_track returns nil when no match" do
    stub_client(
      search_response: { items: [{ id: { videoId: "vid1" }, snippet: { title: "Something - Completely Different" } }] }
    )

    result = @wrapper.find_track(title: "Doxy", artist: "Miles Davis", album: nil)

    assert_nil result
  end

  test "find_track returns nil when no results" do
    stub_client(search_response: { items: [] })

    result = @wrapper.find_track(title: "Nonexistent", artist: "Nobody", album: nil)

    assert_nil result
  end

  test "find_track builds query from title and artist" do
    search = stub_client(search_response: { items: [] })

    @wrapper.find_track(title: "Doxy", artist: "Miles Davis", album: nil)

    assert_equal "Doxy Miles Davis", search.last_query
  end

  test "find_track omits artist from query when nil" do
    search = stub_client(search_response: { items: [] })

    @wrapper.find_track(title: "Doxy", artist: nil, album: nil)

    assert_equal "Doxy", search.last_query
  end

  private

  def assert_parsed(raw_title, artist:, title:)
    result = @wrapper.send(:parse_title, raw_title)
    if artist.nil?
      assert_nil result[:artist], "expected nil artist for '#{raw_title}'"
    else
      assert_equal artist, result[:artist], "expected artist '#{artist}' for '#{raw_title}'"
    end
    assert_equal title, result[:title], "expected title '#{title}' for '#{raw_title}'"
  end

  def stub_playlist_import(tracks)
    items = tracks.map do |t|
      { snippet: { title: t[:title], videoOwnerChannelTitle: t[:channel], resourceId: { videoId: t[:id] } } }
    end
    stub_client(
      find_response: { items: [{ snippet: { title: "Playlist" } }] },
      items_responses: [{ items: items }]
    )
  end

  def stub_client(find_response: nil, items_responses: nil, search_response: nil)
    playlists = StubPlaylists.new(find_response, items_responses || [])
    search    = StubSearch.new(search_response)
    client    = Struct.new(:playlists, :search).new(playlists, search)
    @wrapper.instance_variable_set(:@client, client)
    search
  end

  class StubPlaylists
    def initialize(find_response, items_responses)
      @find_response   = find_response
      @items_responses = items_responses
      @items_call      = 0
    end

    def find(_id)
      @find_response
    end

    def items(_id, params: {})
      response = @items_responses[@items_call]
      @items_call += 1
      response
    end
  end

  class StubSearch
    attr_reader :last_query

    def initialize(response)
      @response = response
    end

    def videos(query, params: {})
      @last_query = query
      @response
    end
  end
end
