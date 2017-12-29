class Document < ActiveRecord::Base
  FORMATS = %w(MARKDOWN HAML HTML )
  belongs_to :changed_by, class_name: "User"
  belongs_to :previous_version, class_name: "Document"

  validates_inclusion_of :content_type, in: FORMATS
  validates_presence_of :title

  scope :current, -> { where(is_current: true)}

  # we define scopes for specific documents.
  # TODO COme up with a better way of doing this
  scope :constitution, -> { where(url: "constitution") }
  scope :code_of_conduct, -> { where(url: "code_of_conduct") }
  scope :rules_discipline, -> { where(url: "rules_discipline") }
  scope :ncc_rules, -> { where(url: "ncc_rules") }
  scope :eligibility, -> { where(url: "eligibility") }
  scope :junior_eligibility, -> { where(url: "junior_eligibility") }


  def to_html
    case content_type
      when "HTML"
        return content.html_safe
      when "HAML"
        engine = Haml::Engine.new(content)
        return engine.render
      when "MARKDOWN"
        converter = MarkdownConverter.new
        return converter.to_html(content, filter_html: false)
    end
    return "Unknown content type"
  end

  def versions
    Document.where(title: title).order("created_at").includes(changed_by: :player)
  end

  private
  class MarkdownConverter
    include Remarkable
  end
end
