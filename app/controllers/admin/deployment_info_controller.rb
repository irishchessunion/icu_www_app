class Admin::DeploymentInfoController < ApplicationController
  before_action :authorize_admin!

  def show
    @deployment_info = DeploymentInfo.current
  end

  private

  def authorize_admin!
    authorize! :show, DeploymentInfo
  end
end
