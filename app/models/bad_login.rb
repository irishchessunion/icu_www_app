class BadLogin < ApplicationRecord
  include Pageable

  validates_presence_of :email, :ip

  def self.new_record(email, ip)
    create!(email: email, ip: ip)
  end

  def self.search(params, path)
    matches = order(created_at: :desc)
    matches = matches.where("email LIKE ?", "%#{params[:email]}%") if params[:email].present?
    matches = matches.where("ip LIKE ?", "%#{params[:ip]}%") if params[:ip].present?
    matches = matches.where("created_at LIKE ?", "%#{params[:time]}%") if params[:time].present?
    paginate(matches, params, path)
  end
end
