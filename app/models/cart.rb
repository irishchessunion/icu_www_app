class Cart < ApplicationRecord
  include Pageable
  include Payable

  MAX_AMOUNT = 10000000.00
  MIN_AMOUNT = 0.0

  has_many :items, dependent: :destroy
  has_many :payment_errors, dependent: :destroy
  has_many :refunds, dependent: :destroy
  belongs_to :user

  validates :total, :original_total, numericality: { less_than: MAX_AMOUNT }, allow_nil: true

  scope :include_items_plus, -> { includes(items: [:fee, :player]) }
  scope :include_items, -> { includes(:items) }
  scope :include_errors, -> { includes(:payment_errors) }
  scope :include_refunds, -> { includes(refunds: { user: :player }) }

  def total_cost
    items.map(&:cost).reduce(0.0, :+)
  end

  def refundable?
    active? && purchased_with_current_payment_account?
  end

  def revokable?
    active?
  end

  def refund_type
    I18n.t("shop.payment.#{purchased_with_current_payment_account?? 'refund' : 'revoke'}")
  end

  def duplicates?(new_item, add_error: false)
    items.each do |item|
      if error = new_item.duplicate_of?(item)
        new_item.errors.add(:base, error) if add_error
        return true
      end
    end
    false
  end

  def last_payment_error_message
    payment_errors.last.try(:message).presence || "None"
  end

  def purchase(params, user)
    email = params[:confirmation_email]
    name = params[:payment_name]
    intent = Stripe::PaymentIntent.retrieve(params[:payment_intent_id]) if params[:payment_intent_id]
    if intent and intent.status == 'succeeded'  
      latest_charge = intent.latest_charge
      Stripe::PaymentIntent.update(intent.id, {description: ["Cart #{id}", name, email].reject { |d| d.nil? }.join(", "),})
      successful_payment("stripe", intent.id, latest_charge, Cart.current_payment_account)
    elsif intent and not intent.status == 'succeeded'
      add_payment_error(intent, name, email, "Something went wrong, please contact webmaster@icu.ie")
      return
    else
      successful_payment("free", nil, nil, Cart.current_payment_account)
    end

    update_cart(total_cost, name, email, user)
    send_receipt
  end

  def pay_with_cash(cash_payment, user)
    successful_payment(cash_payment.payment_method)
    update_cart(cash_payment.amount, cash_payment.name, cash_payment.email, user)
    send_receipt
  end

  def create_intent
    intent = Stripe::PaymentIntent.create({
      amount: cents(self.total_cost),
      currency: 'eur',
    })
    intent
  end

  def refund(item_ids, user)
    automatic = refundable?
    refund = Refund.new(user: user, cart: self, automatic: automatic)
    intent = nil
    charge = nil
    is_old_charge = payment_ref&.start_with?("ch_") and automatic
    is_pi = payment_ref&.start_with?("pi_") and automatic
    intent = Stripe::PaymentIntent.retrieve(payment_ref) if is_pi # new object
    charge = Stripe::Charge.retrieve(payment_ref) if is_old_charge # old object
    
    free_items = items.where(id: item_ids).where(cost: 0)
    non_free_items_ids = items.where(id: item_ids).where.not(cost: 0).ids
    
    if non_free_items_ids.size > 0
      amount = refund_amount(non_free_items_ids, is_pi ? intent : charge, is_old_charge)
      refund.amount = amount

      # new refund method
      stripe_refund_object = Stripe::Refund.create({payment_intent: intent.id, amount: cents(amount)}) if is_pi

      # old refund method
      stripe_refund_object = Stripe::Refund.create({charge: charge.id, amount: cents(amount)}) if is_old_charge

      if (is_pi or is_old_charge) and stripe_refund_object.status == "failed"
        # catch refund failure
        refund.error = "Stripe refund transaction failed"
      else
        items.each do |item|
            if non_free_items_ids.include?(item.id)
                item.refund
            end
        end
        self.total -= refund.amount
      end
    end
    
    free_items.each do |item|
      item.refund
    end
    
    self.status = all_items_refunded? ? "refunded" : "part_refunded"
    
    save!
    refund
  rescue => e
    refund.error = e.message
    refund
  ensure
    refund.save
  end

  def all_items_refunded?
    items.all? &:refunded?
  end

  def any_items_refunded?
    items.any? &:refunded?
  end

  def self.search(params, path)
    params[:status] = "active" if params[:status].nil?
    matches = order(updated_at: :desc).include_items
    matches = where(id: params[:id].to_i) if params[:id].to_i > 0
    if STATUSES.include?(params[:status])
      matches = matches.where(status: params[:status])
    elsif params[:status].match(/\A(in)?active\z/)
      matches = matches.send(params[:status])
    end
    matches = matches.where("payment_name LIKE ?", "%#{params[:name]}%") if params[:name].present?
    matches = matches.where("confirmation_email LIKE ?", "%#{params[:email]}%") if params[:email].present?
    if params[:date].present?
      date = "%#{params[:date]}%"
      matches = matches.where("created_at LIKE ? OR updated_at LIKE ?", date, date)
    end
    paginate(matches, params, path)
  end

  def purchased_with_current_payment_account?
    payment_method == "stripe" && payment_account == Cart.current_payment_account
  end

  def self.current_payment_account
    @current_payment_account ||= Rails.application.secrets.stripe[:public].truncate(32, omission: "")
  end

  def all_notes
    items.each_with_object({}) do |item, notes|
      item.notes.each do |note|
        notes[note] ||= notes.size + 1
      end
    end
  end

  def add_payment_error(error, name, email, message=nil)
    message ||= error[:message] || "Unknown error"
    details = error.try(:json_body)
    if details.nil?
      details = "Code: #{error[:code]}, Type: #{error[:type]}, Message: #{error[:message]}"
    else
      details = details.fetch(:error) { details } if details.is_a?(Hash)
      details.delete(:message) if details.is_a?(Hash) && details[:message] == message
      details = details.to_s
    end
    error = payment_errors.build(message: message.truncate(255), details: details.truncate(255), payment_name: name.to_s.truncate(100), confirmation_email: email.to_s.truncate(50))
    error.save
  end

  private

  def successful_payment(payment_method, payment_intent=nil, latest_charge=nil, payment_account=nil)
    self.status = "paid"
    self.payment_method = payment_method
    self.payment_account = payment_account
    self.payment_ref = payment_intent
    self.latest_charge = latest_charge
    self.payment_completed = Time.now
    items.each { |item| item.complete(payment_method) }
  end

  def update_cart(total, name, email, user)
    self.total = total
    self.original_total = total
    self.payment_name = name
    self.confirmation_email = email
    self.user = user unless user.guest?
    save
  end

  def send_receipt
    return unless paid?
    mail = IcuMailer.payment_receipt(id)
    update_column(:confirmation_text, mail.body.decoded)
    raise "no email address available" unless confirmation_email.present?
    mail.deliver_now
    update_column(:confirmation_sent, true)
  rescue => e
    update_columns(confirmation_sent: false, confirmation_error: e.message.gsub(/\s+/, ' ').truncate(255))
  end

  def cents(euros)
    (euros * 100).to_i
  end

  def refund_amount(item_ids, intent, is_old_charge)
    # Check that the cart_items to be refunded all belong to this cart and have "paid" status.
    refund_amount = 0.0
    item_ids.each do |item_id|
      item = items.find_by(id: item_id)
      raise "Cart item #{item_id} does not belong to this cart" unless item
      raise "Cart item #{item_id} has wrong status (#{item.status})" unless item.paid?
      refund_amount += item.cost
    end

    # If there's a charge object (we're automatically refunding the payment as well as updating the database).
    if intent
      # Check that the ICU cart and Stripe totals are consistent.
      unless cents(original_total) == intent.amount
        raise "Cart amount (#{cents(original_total)}) is inconsistent with Stripe amount (#{intent.amount})"
      end

      # Check any previous refund amounts are consistent.
      cart_refund = cents(original_total) - cents(total)
      charge = intent
      charge = Stripe::Charge.retrieve(intent.latest_charge) unless is_old_charge
      unless cart_refund == charge.amount_refunded
        raise "Previous cart refund (#{cart_refund}) is inconsistent with previous Stripe refund (#{charge.amount_refunded})"
      end
    end

    # Check the proposed refund isn't too large.
    if refund_amount > total
      raise "Refund (#{refund_amount}) is larger than remaining cost (#{total})"
    end

    # Check if the whole cart is being refunded.
    total_refunds = items.select{ |c| c.refunded? }.size + item_ids.size
    if total_refunds > items.size
      raise "Too many refunds (#{total_refunds}) for this cart (#{items.size})"
    elsif total_refunds == items.size
      unless refund_amount == total
        raise "Refund amount (#{refund_amount}) doesn't match total (#{total})"
      end
    else
      free_items = items.select{ |item| item.cost == 0 and not item_ids.include? item.id }
      if free_items.size == 0
        unless refund_amount < total
          raise "Refund amount (#{refund_amount}) should be less than total (#{total})" unless total == 0.0
        end
      else
        unless refund_amount <= total
          raise "Refund amount (#{refund_amount}) should be less than total (#{total})" unless total == 0.0
        end
      end
    end

    # Return the refund amount (in Euros).
    refund_amount
  end
end
