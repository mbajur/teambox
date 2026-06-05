require 'omniauth/core'

# Add mock_auth support to OmniAuth::Configuration (oa-core 0.0.3 doesn't have it)
module OmniAuth
  class Configuration
    def mock_auth
      @mock_auth ||= {}
    end
  end
end

Before do
  OmniAuth.config.mock_auth.clear
end
