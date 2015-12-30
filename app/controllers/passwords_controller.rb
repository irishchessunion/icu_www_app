class PasswordsController < ApplicationController
  # GET /password/new
  # Just displays a forgot password form with a single field for the email address.
  def new
  end

  # POST /password
  def create
    email = params[:email]
    user = User.where(email: email).first
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
      redirect_to root_path, notice: 'Your password was successfully changed.'
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
