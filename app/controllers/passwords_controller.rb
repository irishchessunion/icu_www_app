class PasswordsController < ApplicationController
  # Stops the form being used to flood members with emails or to search for registered addresses. Counted per IP address.
  rate_limit to: 5, within: 3.minutes, only: :create, with: -> { redirect_to new_password_path, alert: t("session.too_many_attempts") }

  # GET /password/new
  # Just displays a forgot password form with a single field for the email address.
  def new
  end

  # POST /password
  def create
    user = User.where(email: params[:email]).first
    unless user
      redirect_to new_password_path, notice: t('password.unknown_email')
      return
    end

    user.send_reset_password_instructions
    redirect_to root_path, notice: t('password.forgotten_password_email_sent')
  end

  # GET /password/edit?token=xxx
  def edit
    if User.where(reset_password_token: params[:token]).exists?
      @password = NewPassword.new(token: params[:token])
    else
      flash[:notice] = "The token is incorrect, please check you copied the whole link in the email and try again"
      @password = nil
    end
  end

  # PUT /password
  def update
    @password = NewPassword.new(password_params)

    if @password.save
      # Sign in as normal, so disabled, unverified and expired accounts are still refused.
      redirect_to switch_to_tls(:sign_in), notice: t("password.changed"), allow_other_host: true
    else
      render :new
    end
  end

  private

  # Only allow a trusted parameter "white list" through.
  def password_params
    params.permit(:new_password, :new_password_confirmation, :token)
  end
end
