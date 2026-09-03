# Declares that an attribute holds content edited via the admin Quill
# WYSIWYG editor (see app/assets/javascripts/wysiwyg_editor.js). Requires the
# including model to have a `markdown` boolean column (the one-way
# markdown-to-HTML migration flag - see Article/News) and to also include
# Remarkable, for #to_html/#sanitize_editor_html/#html_content_blank?.
#
#   wysiwyg_editable :text
#   wysiwyg_editable :summary
#
# Provides, for the declared field:
# - #editor_html: seeds the admin editor, without expanding shortcodes
# - #html: the public rendering (expands shortcodes, then respects markdown)
# - a before_validation sanitizing the field when markdown: false
# - a validation rejecting blank/empty-Quill-placeholder content, on every save
module WysiwygEditable
  extend ActiveSupport::Concern

  class_methods do
    def wysiwyg_editable(field)
      field = field.to_sym

      before_validation :"sanitize_#{field}_for_wysiwyg"
      validate(:"#{field}_must_be_present_for_wysiwyg")

      define_method(:editor_html) do
        raw = public_send(field)
        markdown? ? to_html(raw, filter_html: false) : raw.to_s.html_safe
      end

      define_method(:html) do
        render_wysiwyg_content(expand_all(public_send(field)))
      end

      define_method(:"sanitize_#{field}_for_wysiwyg") do
        public_send(:"#{field}=", sanitize_editor_html(public_send(field))) unless markdown?
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
    markdown? ? to_html(expanded, filter_html: false) : expanded.html_safe
  end
end
