module DocumentsHelper
  def document_content_type_menu(selected)
    cats = Document::FORMATS.map { |cat| [t("document.format.#{cat}"), cat] }
    options_for_select(cats, selected)
  end

  def document_link(document_url)
    doc = Document.current.send(document_url).first
    ret = link_to(doc.title, doc)
    if doc.subtitle.present?
      ret += ": #{doc.subtitle}".html_safe
    end
    return ret
  end
end
