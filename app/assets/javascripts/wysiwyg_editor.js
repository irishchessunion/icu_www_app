// Progressively enhances a .wysiwyg-editor textarea into a Quill WYSIWYG editor.
// Without JS the plain textarea (already seeded with rendered HTML - see
// Article#editor_html / News#editor_html) still works exactly as before.
// Used by the article and news forms, and by the event and club forms via utils/_wysiwyg_area_for.
window.wysiwygEditor = null;
window.wysiwygEditorSavedRange = null;

// Escapes text pulled from a data-* attribute (e.g. a linked record's title)
// before it gets embedded in a [ART:1:Title] shortcode, so a malicious title
// can't break out of the shortcode and inject markup when it's later expanded.
function escapeWysiwygHtml(text) {
  return String(text)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

// Inserts plain text (e.g. an [ART:1:Title] shortcode) at the cursor position the
// editor had when one of the "Link Article" / "Link Event" / "Insert Image" buttons
// was pressed (captured on mousedown, before the modal steals focus).
function insertWysiwygToken(text) {
  var quill = window.wysiwygEditor;
  if (!quill) return;
  var range = window.wysiwygEditorSavedRange || quill.getSelection(true) || { index: quill.getLength(), length: 0 };
  quill.insertText(range.index, text, "user");
  quill.setSelection(range.index + text.length, 0);
}

$(function() {
  var textarea = document.querySelector(".wysiwyg-editor");
  if (!textarea) return;

  // Extend Quill's list blots: https://quilljs.com/docs/customization#extending-blots
  var ListItem = Quill.import("formats/list");
  var OrderedList = Quill.import("formats/list-container");

  class UnorderedList extends OrderedList {}
  UnorderedList.blotName = "unordered-list-container";
  UnorderedList.tagName = "UL";

  class ListItemWithUnorderedList extends ListItem {
    optimize(context) {
      super.optimize(context);
      var container = this.domNode.getAttribute("data-list") === "bullet" ? UnorderedList : OrderedList;
      if (this.parent.statics.blotName !== container.blotName) {
        var list = this.parent.isolate(this.offset(this.parent), this.length());
        list.replaceWith(container.blotName);
      }
    }
  }

  Quill.register(UnorderedList);
  Quill.register(ListItemWithUnorderedList, true);

  var container = document.createElement("div");
  container.id = "wysiwyg_editor_mount";
  container.innerHTML = textarea.value;
  textarea.style.display = "none";
  textarea.parentNode.insertBefore(container, textarea.nextSibling);

  // Each value is a method of Quill's table module: https://quilljs.com/docs/modules/table
  var tableActions = {
    insertTable: "Insert table",
    insertRowAbove: "Add row above",
    insertRowBelow: "Add row below",
    insertColumnLeft: "Add column left",
    insertColumnRight: "Add column right",
    deleteRow: "Delete row",
    deleteColumn: "Delete column",
    deleteTable: "Delete table"
  };

  var quill = new Quill(container, {
    theme: "snow",
    modules: {
      table: true,
      toolbar: {
        container: [
          [{ header: [2, 3, false] }],
          ["bold", "italic", "underline", "strike"],
          [{ list: "ordered" }, { list: "bullet" }],
          ["blockquote", "link"],
          [{ "table-menu": Object.keys(tableActions) }],
          ["clean"]
        ],
        handlers: {
          // The row and column actions do nothing unless the cursor is in a table
          "table-menu": function(action) {
            var editor = this.quill;
            var table = editor.getModule("table");
            if (action !== "insertTable") return table[action]();
            if (table.getTable()[0]) return;
            // Start the table on a new line, or Quill puts the text of the current one in its first cell
            var line = editor.getLine(editor.getSelection(true).index)[0];
            if (line.length() > 1) {
              var end = editor.getIndex(line) + line.length() - 1;
              editor.insertText(end, "\n", "user");
              editor.setSelection(end + 1, 0, "user");
            }
            table.insertTable(3, 3);
          }
        }
      }
    }
  });

  quill.getModule("toolbar").container.querySelectorAll(".ql-table-menu .ql-picker-item").forEach(function(item) {
    item.setAttribute("data-label", tableActions[item.getAttribute("data-value")]);
  });

  window.wysiwygEditor = quill;
  container.__quill = quill; // exposed for feature specs to drive via execute_script

  $("#wysiwyg_toolbar_extra button").on("mousedown", function() {
    window.wysiwygEditorSavedRange = quill.getSelection();
  });

  $(textarea).closest("form").on("submit", function() {
    textarea.value = quill.root.innerHTML;
  });

  // Posts the unsaved text to a preview page, always in the same tab, so pressing Preview again refreshes it
  $("[data-wysiwyg-preview]").on("click", function() {
    var fields = {
      text: quill.root.innerHTML,
      title: $($(this).data("wysiwyg-preview-title")).val(),
      authenticity_token: $("meta[name=csrf-token]").attr("content")
    };
    var form = $("<form>", { method: "post", action: $(this).data("wysiwyg-preview"), target: "wysiwyg_preview" });
    $.each(fields, function(name, value) {
      form.append($("<input>", { type: "hidden", name: name, value: value }));
    });
    form.appendTo("body").submit().remove();
  });
});
