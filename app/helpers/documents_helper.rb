module DocumentsHelper
  def document_content_type_menu(selected)
    cats = Document::FORMATS.map { |cat| [t("document.format.#{cat}"), cat] }
    options_for_select(cats, selected)
  end
end
