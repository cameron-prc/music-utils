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
    artist1 = build(:artist, name: "Artist 1").tap { |artist| artist.external_ids.build(provider: @provider, external_id: "spotify_artist_1") }
    artist2 = build(:artist, name: "Artist 2").tap { |artist| artist.external_ids.build(provider: @provider, external_id: "spotify_artist_2") }
    artist3 = build(:artist, name: "Artist 3").tap { |artist| artist.external_ids.build(provider: @provider, external_id: "spotify_artist_3") }

    album = build(:album, title: "Album 1", release_date: "2020-01-01").tap do |album|
      album.external_ids.build(provider: @provider, external_id: "spotify_album_1")
      album.album_artists = [
        build(:album_artist, artist: artist1, album: album, position: 0),
        build(:album_artist, artist: artist2, album: album, position: 1)
      ]
    end

    track1 = build(:track, title: "Track 1", album: album).tap do |track|
      track.external_ids.build(provider: @provider, external_id: "spotify_track_1")
      track.track_artists = [
        build(:track_artist, artist: artist1, track: track, position: 0),
        build(:track_artist, artist: artist2, track: track, position: 1)
      ]
    end

    track2 = build(:track, title: "Track 2", album: album).tap do |track|
      track.external_ids.build(provider: @provider, external_id: "spotify_track_2")
      track.track_artists = [
        build(:track_artist, artist: artist1, track: track, position: 0),
        build(:track_artist, artist: artist2, track: track, position: 1),
        build(:track_artist, artist: artist3, track: track, position: 2)
      ]
    end

    build(:playlist, name: name).tap do |playlist|
      playlist.playlist_tracks = [
        build(:playlist_track, track: track1, playlist: playlist, position: 0),
        build(:playlist_track, track: track2, playlist: playlist, position: 1)
      ]
    end
  end

  def create_existing_playlist
    album = create(:album)
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
