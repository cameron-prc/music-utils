module SpotifyClient::Nextable
  def next(url)
    uri = URI.parse(url)
    @request.call(:get, uri.path, params: Rack::Utils.parse_nested_query(uri.query))
  end
end
