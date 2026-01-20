module Admin::FeesHelper
  def fee_description(fee)
    if fee.type == "Fee::Entry"
      "#{fee.name} #{fee.year || fee.years}"
    elsif fee.type == "Fee::Subscription"
      "#{fee.name} #{fee.year || fee.years}"
    elsif fee.type == "Fee::Other"
      fee.name
    else
      "No idea"
    end
  end

  def fee_event_link(fee)
    if fee.type == "Fee::Entry" && fee.event_id.present?
      link_to fee.event.name, event_path(fee.event)
    elsif fee.type == "Fee::Subscription"
      "Subscription"
    elsif fee.type == "Fee::Other"
      "Other"
    else
      "No idea"
    end
  end
end
