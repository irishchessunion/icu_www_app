class Admin::JuniorNewslettersController < ApplicationController
  authorize_resource

  def index
    users = User.where(junior_newsletter: true)
    generator = Admin::JuniorNewsletter.new
    send_data generator.generate(users), filename: "junior_newsletter.csv", type: 'text/csv'
  end
end
