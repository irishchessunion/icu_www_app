class Login < ApplicationRecord
  include Pageable

  belongs_to :user
  validates_presence_of :ip, :user_id

  def self.search(params, path)
    matches = order(created_at: :desc).includes(user: :player)
    if params[:last_name].present? || params[:first_name].present? || params[:email].present? || params[:player_id].present?
      matches = matches.joins(user: :player)
      matches = matches.where("players.last_name LIKE ?", "%#{params[:last_name]}%") if params[:last_name].present?
      matches = matches.where("players.first_name LIKE ?", "%#{params[:first_name]}%") if params[:first_name].present?
      matches = matches.where("players.id = ?", params[:player_id].to_i) if params[:player_id].to_i > 0
      matches = matches.where("users.email LIKE ?", "%#{params[:email]}%") if params[:email].present?
    end
    matches = matches.where("logins.ip LIKE ?", "%#{params[:ip]}%") if params[:ip].present?
    params[:result] = "Success" if params[:result].nil?
    case params[:result]
      when "Success"      then matches = matches.where(error: nil)
      when "Failure"      then matches = matches.where.not(error: nil)
      when "Bad password" then matches = matches.where(error: "invalid_password")
      when "Expired"      then matches = matches.where(error: "subscription_expired")
      when "Disabled"     then matches = matches.where(error: "account_disabled")
      when "Unverified"   then matches = matches.where(error: "unverified_email")
    end
    paginate(matches, params, path)
  end
end
