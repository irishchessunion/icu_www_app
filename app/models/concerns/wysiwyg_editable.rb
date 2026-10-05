# Declares that an attribute holds content edited via the admin Quill
# WYSIWYG editor (see app/assets/javascripts/wysiwyg_editor.js). Requires the
# including model to have a `markdown` boolean column (the one-way
# markdown-to-HTML migration flag - see Article/News) and to also include
# Remarkable, for #to_html/#sanitize_editor_html/#html_content_blank?.
#
#   wysiwyg_editable :text
#   wysiwyg_editable :summary
#   wysiwyg_editable :note, required: false, filter_html: true
#
# Options:
# - required: false skips the not-blank validation, for optional fields
# - filter_html: true strips raw HTML from legacy Markdown content when it's rendered,
#   for fields edited by less trusted users (event organisers, club secretaries)
#
# Provides, for the declared field:
# - #editor_html: seeds the admin editor, without expanding shortcodes
# - #html: the public rendering (expands shortcodes, then respects markdown)
# - a before_validation sanitizing the field when markdown: false (and, for an optional
#   field, clearing an empty Quill placeholder such as "<p><br></p>")
# - a validation rejecting blank/empty-Quill-placeholder content, on every save (unless required: false)
module WysiwygEditable
  extend ActiveSupport::Concern

  included do
    class_attribute :wysiwyg_filter_html, default: false
  end

  class_methods do
    def wysiwyg_editable(field, required: true, filter_html: false)
      field = field.to_sym
      self.wysiwyg_filter_html = filter_html

      before_validation :"sanitize_#{field}_for_wysiwyg"
      validate(:"#{field}_must_be_present_for_wysiwyg") if required

      define_method(:editor_html) do
        raw = public_send(field)
        markdown? ? to_html(raw, filter_html: wysiwyg_filter_html) : raw.to_s.html_safe
      end

      define_method(:html) do
        render_wysiwyg_content(expand_all(public_send(field)))
      end

      define_method(:"sanitize_#{field}_for_wysiwyg") do
        return if markdown?
        value = sanitize_editor_html(public_send(field))
        value = nil if !required && html_content_blank?(value)
        public_send(:"#{field}=", value)
      end

      define_method(:"#{field}_must_be_present_for_wysiwyg") do
        errors.add(field, "can't be blank") if html_content_blank?(public_send(field))
      end

      private :"sanitize_#{field}_for_wysiwyg", :"#{field}_must_be_present_for_wysiwyg"
    end
  end

  # Renders already-expanded editor content, respecting the markdown flag.
  # #html (above) uses this directly; models with more than one rendering of
  # the same field (e.g. News#html2) can reuse it too.
  def render_wysiwyg_content(expanded)
    markdown? ? to_html(expanded, filter_html: wysiwyg_filter_html) : expanded.html_safe
  end
end
