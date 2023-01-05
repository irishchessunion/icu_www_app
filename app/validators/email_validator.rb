class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless Global.valid_email?(value)
      record.errors.add attribute, message: (options[:message] || I18n.t("errors.messages.invalid"));
    end
  end
end
