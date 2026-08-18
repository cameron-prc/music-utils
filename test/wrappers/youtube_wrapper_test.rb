require "test_helper"

class YoutubeWrapperTest < ActiveSupport::TestCase
  setup do
    @wrapper = YoutubeWrapper.allocate
  end

  test "get_playlist returns external playlist with tracks" do
    stub_client(
      find_response: { items: [{ snippet: { title: "My Playlist" } }] },
      items_responses: [
        { items: [
          { snippet: { title: "Song One", videoOwnerChannelTitle: "Artist A", resourceId: { videoId: "vid1" } } },
          { snippet: { title: "Song Two", videoOwnerChannelTitle: "Artist B", resourceId: { videoId: "vid2" } } }
        ] }
      ]
    )

    result = @wrapper.get_playlist("PLtest123")

    assert_equal "My Playlist", result.name
    assert_equal Providers::YOUTUBE, result.provider
    assert_equal 2, result.tracks.size
    assert_equal "Song One", result.tracks[0].name
    assert_equal "vid1", result.tracks[0].id
    assert_equal "Artist A", result.tracks[0].artist_refs[0].name
  end

  test "get_playlist paginates through multiple pages" do
    stub_client(
      find_response: { items: [{ snippet: { title: "Big Playlist" } }] },
      items_responses: [
        { items: [{ snippet: { title: "Track 1", videoOwnerChannelTitle: "Ch1", resourceId: { videoId: "v1" } } }],
          nextPageToken: "page2token" },
        { items: [{ snippet: { title: "Track 2", videoOwnerChannelTitle: "Ch2", resourceId: { videoId: "v2" } } }] }
      ]
    )

    result = @wrapper.get_playlist("PLbig")

    assert_equal 2, result.tracks.size
    assert_equal "Track 1", result.tracks[0].name
    assert_equal "Track 2", result.tracks[1].name
  end

  test "find_track returns video id when title matches" do
    stub_client(
      search_response: { items: [
        { id: { videoId: "match1" }, snippet: { title: "Doxy - Official Audio" } },
        { id: { videoId: "other" }, snippet: { title: "Something Else" } }
      ] }
    )

    result = @wrapper.find_track(title: "Doxy", artist: "Miles Davis", album: nil)

    assert_equal "match1", result
  end

  test "find_track matches case-insensitively with include" do
    stub_client(
      search_response: { items: [{ id: { videoId: "vid1" }, snippet: { title: "DOXY (Remastered)" } }] }
    )

    result = @wrapper.find_track(title: "Doxy", artist: "Miles Davis", album: nil)

    assert_equal "vid1", result
  end

  test "find_track returns nil when no match" do
    stub_client(
      search_response: { items: [{ id: { videoId: "vid1" }, snippet: { title: "Completely Different Song" } }] }
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
