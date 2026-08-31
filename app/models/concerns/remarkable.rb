module Remarkable
  # Tags/attributes the Quill WYSIWYG editor's toolbar can actually produce.
  # Used to sanitize content submitted as pre-rendered HTML (markdown: false),
  # since the client-side editor can be bypassed entirely by posting directly
  # to the create/update endpoints.
  EDITOR_ALLOWED_TAGS = %w[p h2 h3 strong em u s ol ul li blockquote a br].freeze
  EDITOR_ALLOWED_ATTRIBUTES = %w[href].freeze

  def to_html(text, filter_html: true)
    return "" unless text.present?
    renderer = Redcarpet::Render::HTML.new(filter_html: filter_html)
    markdown = Redcarpet::Markdown.new(renderer, no_intra_emphasis: true, autolink: true, strikethrough: true, underline: true, tables: true)
    compensate_redcarpet_ema_escaping(markdown.render(text)).html_safe
  end

  # Strips anything a legitimate Quill editor session couldn't have produced
  # (script tags, event handler attributes, etc). Only meaningful for content
  # stored as pre-rendered HTML - markdown-source text is left untouched.
  def sanitize_editor_html(html)
    return html if html.blank?
    Rails::Html::SafeListSanitizer.new.sanitize(
      html, tags: EDITOR_ALLOWED_TAGS, attributes: EDITOR_ALLOWED_ATTRIBUTES
    ).to_s
  end

  # An empty Quill editor still submits "<p><br></p>", which is not blank as
  # far as ActiveModel's presence validator is concerned. Strip tags/&nbsp;
  # to find out whether there's any real content left.
  def html_content_blank?(html)
    html.to_s.gsub(/<[^>]*>/, "").gsub(/&nbsp;/i, " ").strip.empty?
  end

  private

  def compensate_redcarpet_ema_escaping(string)
    string.gsub(/<script>liame\(.*?\)<\/script>/i) do |match|
      match.gsub("&lt;", "<").gsub("&gt;", ">").gsub("&quot;", '"').gsub("&#39;", "'")
    end
  end
end
