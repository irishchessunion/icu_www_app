class DateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    constraints = options.each_with_object({}) do |(k,v), h|
      h[k.to_sym] = v if k.to_s.match(/\A(on_or_)?(after|before)\z/)
    end
    date = ICU::Date.new(value, constraints)
    unless date.valid?
      if options[:message]
        message = options[:message]
      elsif date.reasons[1]
        message = I18n.t(date.reasons[0], **date.reasons[1])
      else
        message = I18n.t(date.reasons[0])
      end
      record.errors.add attribute, :invalid_date, message: message
    end
  end
end
