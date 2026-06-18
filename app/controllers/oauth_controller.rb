class OauthController < ApplicationController
  def authorise_spotify
    session[:oauth_state] = SecureRandom.hex(16)
    redirect_to SpotifyClient::Authorisation.build_authorisation_url(state: session[:oauth_state]), allow_other_host: true
  end

  def callback_spotify
    unless params[:state] == session.delete(:oauth_state)
      redirect_to root_path, alert: "OAuth state mismatch"
      return
    end

    if params[:errors]&.any?
      redirect_to root_path, alert: params[:errors]
    end

    tokens = SpotifyClient::Authorisation.request_access_tokens(params[:code])

    Current.user.oauth_tokens.find_or_initialize_by(provider: Providers::SPOTIFY).tap do |token|
      token.update!(
        access_token:  tokens[:access_token],
        refresh_token: tokens[:refresh_token],
        expires_at:    Time.now + tokens[:expires_in]
      )
    end

    redirect_to root_path, notice: "Spotify connected"
  end
end
