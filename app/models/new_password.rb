class NewPassword
  include ActiveModel::Model # see https://github.com/rails/rails/blob/master/activemodel/lib/active_model/model.rb

  attr_accessor :token, :new_password, :new_password_confirm
  attr_reader :user

  validates_presence_of :token, :new_password, :new_password_confirm
  validates_length_of :new_password, minimum: User::MINIMUM_PASSWORD_LENGTH, message: I18n.t('errors.attributes.password.length')
  validates_format_of :new_password, with: /\d/, message: I18n.t('errors.attributes.password.digits')
  validates_confirmation_of :new_password

  def initialize(attributes={})
    attributes.each do |name, value|
      public_send("#{name}=", value)
    end
  end

  def save
    @user = User.where(reset_password_token: token).first
    unless @user
      errors.add(:base, 'Invalid token')
      return false
    end
    unless @user.reset_password_period_valid?
      errors.add(:base, 'Token expired')
      return false
    end
    @user.password = new_password
    @user.send(:update_password_if_present)
    unless @user.errors[:password].empty?
      return false
    end
    @user.clear_reset_password_token
    @user.save!
    true
  end
end
