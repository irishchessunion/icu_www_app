class Admin::ApiKeysController < ApplicationController
  before_action :set_api_key, only: [:show, :edit, :update]
  authorize_resource

  def index
    @api_keys = ApiKey.ordered
  end

  def show
    @entries = @api_key.journal_search
  end

  def new
    @api_key = ApiKey.new
  end

  # The key is shown by rendering the new record, not redirecting to it, as it can't be read back afterwards.
  def create
    @api_key = ApiKey.new(api_key_params)

    if @api_key.save
      @api_key.journal(:create, current_user, request.remote_ip)
      flash.now.notice = "API key was successfully created"
      render action: "show"
    else
      flash_first_error(@api_key, base_only: true)
      render action: "new"
    end
  end

  def update
    if @api_key.update(api_key_params)
      @api_key.journal(:update, current_user, request.remote_ip)
      redirect_to [:admin, @api_key], notice: "API key was successfully updated"
    else
      flash_first_error(@api_key, base_only: true)
      render action: "edit"
    end
  end

  private

  def set_api_key
    @api_key = ApiKey.find(params[:id])
  end

  def api_key_params
    params[:api_key].permit(:name, :active, permissions: [])
  end
end
