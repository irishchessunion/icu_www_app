module Admin
  class ResultsController < ApplicationController
    before_action :set_result, only: [:ban, :edit, :update, :destroy]
    authorize_resource

    # GET /results
    def index
      @results = Result.order('created_at DESC').all
    end

    # GET /results/new
    def new
      @result = Result.new
    end

    # GET /results/1/edit
    def edit
    end

    # POST /results
    def create
      @result = Result.new(result_params)
      @result.reporter_id = current_user.id

      if @result.save
        redirect_to home_path, notice: 'Result was successfully created.'
      else
        render :new
      end
    end

    # PATCH/PUT /results/1
    def update
      if @result.update(result_params)
        redirect_to home_path, notice: 'Result was successfully updated.'
      else
        render :edit
      end
    end

    # POST /results/1/ban
    def ban
      @result.update(active: false)
      @result.reporter.update(disallow_reporting: true)
      redirect_to home_path, notice: 'Result was successfully destroyed.'
    end

    # DELETE /results/1
    def destroy
      @result.destroy
      redirect_to home_path, notice: 'Result was successfully destroyed.'
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_result
        @result = Result.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def result_params
        params.require(:result).permit(:competition, :player1, :player2, :score, :message, :active)
      end
  end
end