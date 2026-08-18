require "test_helper"

class Playlists::HydrateTest < ActiveSupport::TestCase
  setup do
    @provider = Providers::SPOTIFY
  end

  test "creates external IDs for tracks missing them" do
    playlist = create_playlist_with_tracks(2)

    stub_wrapper({ "Track 1" => "nav_1", "Track 2" => "nav_2" }) do
      results = Playlists::Hydrate.new(nil, playlist.id, @provider).call

      assert_equal 2, results[:resolved]
      assert_equal 0, results[:unresolved]
    end

    playlist.tracks.each do |track|
      assert_not_nil track.external_id_for(@provider)
    end
  end

  test "skips tracks that already have an external ID for the target provider" do
    playlist = create_playlist_with_tracks(2)
    track = playlist.tracks.first
    create(:external_id, internal: track, provider: @provider, external_id: "already_resolved")

    stub_wrapper({ "Track 2" => "nav_2" }) do
      results = Playlists::Hydrate.new(nil, playlist.id, @provider).call

      assert_equal 1, results[:resolved]
      assert_equal 0, results[:unresolved]
    end
  end

  test "reports unresolved tracks when wrapper returns nil" do
    playlist = create_playlist_with_tracks(2)

    stub_wrapper({ "Track 1" => "nav_1" }) do
      results = Playlists::Hydrate.new(nil, playlist.id, @provider).call

      assert_equal 1, results[:resolved]
      assert_equal 1, results[:unresolved]
    end

    matched   = playlist.tracks.find_by(title: "Track 1")
    unmatched = playlist.tracks.find_by(title: "Track 2")

    assert_not_nil matched.external_id_for(@provider)
    assert_nil unmatched.external_id_for(@provider)
  end

  private

  def create_playlist_with_tracks(count)
    album = create(:album_ref)

    create(:playlist).tap do |playlist|
      count.times do |i|
        track = create(:track, title: "Track #{i + 1}", album: album)
        create(:playlist_track, playlist: playlist, track: track, position: i)
      end
    end
  end

  def stub_wrapper(matches, &block)
    wrapper = Object.new.tap do |stub|
      stub.define_singleton_method(:find_track) do |title:, artist:, album:|
        matches[title]
      end
    end

    wrapper_class = Class.new.tap { |klass| klass.define_singleton_method(:new) { |_user| wrapper } }
    Playlists::Hydrate::WRAPPERS.define_singleton_method(:fetch) { |_provider| wrapper_class }
    yield
  ensure
    Playlists::Hydrate::WRAPPERS.singleton_class.remove_method(:fetch)
  end
end
