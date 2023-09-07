class PaymentError < ApplicationRecord
  include Pageable

  belongs_to :cart
  scope :ordered, -> { order(created_at: :desc) }

  def self.search(params, path)
    matches = ordered
    %w[message details payment_name confirmation_email created_at].each do |property|
      matches = matches.where("#{property} LIKE ?", "%#{params[property.to_sym]}%") if params[property.to_sym].present?
    end
    paginate(matches, params, path)
  end
end
