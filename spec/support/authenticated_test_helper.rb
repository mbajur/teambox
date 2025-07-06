module AuthenticatedTestHelper
  protected

  def login_as(user, *args)
    user = FactoryBot.create(user, *args) unless user.nil? or user.is_a? User

    user.sessions.create!.tap do |session|
      Current.session = session
      cookies.signed.permanent[:session_token] = { value: session.token, httponly: true, same_site: :lax }
    end

    user
  end

  def login_as_with_oauth_scope(user, scope)
    user = FactoryBot.create(user, *args) unless user.nil? or user.is_a? User
    app = ClientApplication.first || FactoryBot.create(:client_application)
    user.current_token = OauthToken.find_by_user_id(user.id) || Oauth2Token.create!(user: user, client_application: app, scope: scope)
    user.current_token.scope = scope
    user.current_token.save
    user
  end

  def authorize_as(user)
    @request.env["HTTP_AUTHORIZATION"] = user ? ActionController::HttpAuthentication::Basic.encode_credentials(users(user).login, 'monkey') : nil
  end
end
