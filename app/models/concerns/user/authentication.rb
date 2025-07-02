module User::Authentication
  extend ActiveSupport::Concern

  # include Authentication
  # include Authentication::ByPassword
  # include Authentication::ByCookieToken

  included do
    attr_accessor :current_token
  end

  class_methods do
    def authenticate(login, password)
      unless login.blank? or password.blank?
        u = find_by_username_or_email(login)
        u && u.authenticated?(password) ? u : nil
      end
    end
  end

  def encrypt(password)
    self.class.password_digest(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def encrypt_password
    return if password.blank?
    self.salt = self.class.make_token if new_record?
    self.crypted_password = encrypt(password)
    self.password = self.password_confirmation = nil
  end

  def password_required?
    crypted_password.blank? || !password.blank?
  end
end
