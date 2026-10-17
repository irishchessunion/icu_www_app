class EmailValidator < ActiveModel::EachValidator
  # RFC 5321 limit
  MAX_LENGTH = 254

  def validate_each(record, attribute, value)
    if value.to_s.length > MAX_LENGTH
      record.errors.add attribute, :too_long, count: MAX_LENGTH
    elsif !Global.valid_email?(value)
      record.errors.add attribute, message: (options[:message] || I18n.t("errors.messages.invalid"));
    end
  end
end
