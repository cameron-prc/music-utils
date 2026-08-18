require "test_helper"

class Playlists::ImportTest < ActiveSupport::TestCase
  setup do
    @playlist_id = "spotify_playlist_123"
    @provider    = Providers::SPOTIFY
  end

  test "creates a new playlist with artists, albums, and tracks" do
    stub_wrappers(build_playlist_response) do
      Playlists::Import.new(nil, @playlist_id, @provider).call
    end

    assert_equal 1, Playlist.count
    assert_equal 3, Artist.count
    assert_equal 1, Album.count
    assert_equal 2, Track.count

    playlist = Playlist.first

    assert_equal "My Playlist", playlist.name
    assert_equal @playlist_id, playlist.external_ids.first.external_id
    assert_equal 2, playlist.playlist_tracks.count
  end

  test "replaces tracks and updates name on an existing playlist" do
    existing = create_existing_playlist

    stub_wrappers(build_playlist_response(name: "Updated Name")) do
      Playlists::Import.new(nil, @playlist_id, @provider).call
    end

    existing.reload

    assert_equal "Updated Name", existing.name
    assert_equal 2, existing.playlist_tracks.count
    assert_equal 3, Track.count # old track orphaned, not deleted
  end

  private

  def build_playlist_response(name: "My Playlist")
    artist1 = build(:external_artist_ref, name: "Artist 1", provider: Providers::SPOTIFY)
    artist2 = build(:external_artist_ref, name: "Artist 2", provider: Providers::SPOTIFY)
    artist3 = build(:external_artist_ref, name: "Artist 3", provider: Providers::SPOTIFY)

    album = build(:external_album_ref, name: "Album 1", release_date: "2020-01-01", provider: Providers::SPOTIFY, artist_refs: [artist1, artist2])

    track1 = build(:external_track, name: "Track 1", album_ref: album, provider: Providers::SPOTIFY, artist_refs: [artist1, artist2])
    track2 = build(:external_track, name: "Track 2", album_ref: album, provider: Providers::SPOTIFY, artist_refs: [artist1, artist2, artist3])

    build(:external_playlist, name: name, provider: Providers::SPOTIFY, id: @playlist_id).tap do |external_playlist|
      external_playlist.tracks = [track1, track2]
    end
  end

  def create_existing_playlist
    album = create(:album_ref)
    track = create(:track, album: album)

    create(:playlist, name: "Old Name").tap do |playlist|
      create(:external_id, internal: playlist, external_id: @playlist_id)
      create(:playlist_track, playlist: playlist, track: track, position: 0)
    end
  end

  def stub_wrappers(response, &block)
    wrapper = Object.new.tap { |stub| stub.define_singleton_method(:get_playlist) { |_id| response } }
    wrapper_class = Class.new.tap { |klass| klass.define_singleton_method(:new) { |_user| wrapper } }
    Playlists::Import::WRAPPERS.define_singleton_method(:fetch) { |_provider| wrapper_class }
    yield
  ensure
    Playlists::Import::WRAPPERS.singleton_class.remove_method(:fetch)
  end
end
