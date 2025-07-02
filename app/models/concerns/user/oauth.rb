module User::Oauth
  extend ActiveSupport::Concern

  included do
    has_many :client_applications
    has_many :tokens, -> { order("authorized_at desc").include(:client_application) }, class_name: "OauthToken"
  end
end
