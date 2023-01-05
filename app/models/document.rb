class Document < ApplicationRecord
  FORMATS = %w(MARKDOWN HAML HTML )
  belongs_to :changed_by, class_name: "User"
  belongs_to :previous_version, class_name: "Document"

  validates_inclusion_of :content_type, in: FORMATS
  validates_presence_of :title, :url
  validate :content_convertible_to_html

  scope :current, -> { where(is_current: true)}

  # we define scopes for all the ICU documents.
  Global::ICU_DOCS.each_key do |page|
    scope page, -> { where(url: page.to_s) }
  end

  def to_html
    case content_type
      when "HTML"
        return content.html_safe
      when "HAML"
        return haml_to_html
      when "MARKDOWN"
        return markdown_to_html
    end
    return "Unknown content type"
  rescue => e
    return "Error while producing HTML for this document: " + e.message
  end

  def versions
    Document.where(title: title).order("created_at").includes(changed_by: :player)
  end

  private

  def haml_to_html
    engine = Haml::Engine.new(content)
    return engine.render
  end

  def markdown_to_html
    converter = MarkdownConverter.new
    return converter.to_html(content, filter_html: false)
  end

  class MarkdownConverter
    include Remarkable
  end

  def content_convertible_to_html
    case content_type
      when "HTML"
        return
      when "HAML"
        haml_to_html
      when "MARKDOWN"
        markdown_to_html
      else
        errors.add(:content, "Unknown content_type #{content_type}")
    end
  rescue => e
    errors.add(:content, "Content not valid - #{e.message}")
  end

end
