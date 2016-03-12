module Admin
  class SponsorsController < ApplicationController
    before_action :set_sponsor, only: [:show, :edit, :update, :destroy]
    authorize_resource

    # GET /admin/sponsors/1
    def show
      authorize! :show, @sponsor # for some reason, this is needed to ensure a player can only view their own data
      @prev_next = Util::PrevNext.new(session, Sponsor, params[:id], admin: true) if can?(:manage, Sponsor)
      @entries = @sponsor.journal_search if can?(:create, Sponsor)
    end

    # GET /sponsors
    def index
      @sponsors = Sponsor.all
    end

    # GET /sponsors/new
    def new
      @sponsor = Sponsor.new(clicks: 0)
    end

    # GET /sponsors/1/edit
    def edit
    end

    # POST /sponsors
    def create
      @sponsor = Sponsor.new(sponsor_params)

      if @sponsor.save
        @sponsor.journal(:create, current_user, request.remote_ip)
        redirect_to [:admin, @sponsor], notice: "Sponsor was successfully created"
      else
        flash_first_error(@sponsor, base_only: true)
        render action: "new"
      end
    end

    # PATCH/PUT /sponsors/1
    def update
      if @sponsor.update(sponsor_params)
        @sponsor.journal(:update, current_user, request.remote_ip)
        redirect_to [:admin, @sponsor], notice: 'Sponsor was successfully updated.'
      else
        flash_first_error(@sponsor, base_only: true)
        render :edit
      end
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_sponsor
        @sponsor = Sponsor.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def sponsor_params
        params.require(:sponsor).permit(:name, :weight, :weblink, :logo, :contact_name, :contact_email, :contact_phone, :notes)
      end
  end
end