// Progressively enhances the #article_text textarea on the admin article form into a
// Quill WYSIWYG editor. Without JS the plain textarea (already seeded with rendered
// HTML - see Article#editor_html) still works exactly as before.
// See app/views/admin/articles/_form.html.haml.
window.articleQuill = null;
window.articleQuillSavedRange = null;

// Inserts plain text (e.g. an [ART:1:Title] shortcode) at the cursor position the
// editor had when one of the "Link Article" / "Link Event" / "Insert Image" buttons
// was pressed (captured on mousedown, before the modal steals focus).
function insertArticleEditorToken(text) {
  var quill = window.articleQuill;
  if (!quill) return;
  var range = window.articleQuillSavedRange || quill.getSelection(true) || { index: quill.getLength(), length: 0 };
  quill.insertText(range.index, text, "user");
  quill.setSelection(range.index + text.length, 0);
}

$(function() {
  var textarea = document.querySelector("#article_text");
  if (!textarea) return;

  var container = document.createElement("div");
  container.id = "article-editor";
  container.innerHTML = textarea.value;
  textarea.style.display = "none";
  textarea.parentNode.insertBefore(container, textarea.nextSibling);

  var quill = new Quill(container, {
    theme: "snow",
    modules: {
      toolbar: [
        [{ header: [2, 3, false] }],
        ["bold", "italic", "underline", "strike"],
        [{ list: "ordered" }, { list: "bullet" }],
        ["blockquote", "link"],
        ["clean"]
      ]
    }
  });

  window.articleQuill = quill;
  container.__quill = quill; // exposed for feature specs to drive via execute_script

  $("#article_toolbar_extra button").on("mousedown", function() {
    window.articleQuillSavedRange = quill.getSelection();
  });

  $(textarea).closest("form").on("submit", function() {
    textarea.value = quill.root.innerHTML;
  });
});
