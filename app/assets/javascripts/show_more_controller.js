// Stimulus controller that caps the height of long content (e.g. news items
// on the home page) and adds a "Show more" / "Show less" toggle. The toggle
// only appears when the content is actually taller than the cap, which is
// rechecked as images load and when the window is resized. Without JS the
// content is shown in full. The toggle is a plain link under the content,
// like "Show more" on long posts on X. Moving the keyboard focus to a link
// in the cut-off part also expands the content.
class ShowMoreController extends Controller {
  static targets = ["content", "button"]
  static values = { more: String, less: String }

  connect() {
    this.expanded = false;
    this.contentTarget.classList.add("collapsed");
    this.update = this.update.bind(this);
    this.contentTarget.addEventListener("load", this.update, true);
    this.update();
  }

  disconnect() {
    this.contentTarget.removeEventListener("load", this.update, true);
  }

  update() {
    if (this.expanded) return;
    const content = this.contentTarget;
    const overflowing = content.scrollHeight > content.clientHeight + 1;
    content.classList.toggle("overflowing", overflowing);
    this.buttonTarget.classList.toggle("hidden", !overflowing);
  }

  toggle(event) {
    event.preventDefault();
    this.setExpanded(!this.expanded);
    if (!this.expanded) {
      if (this.element.getBoundingClientRect().top < 0) this.element.scrollIntoView();
      this.update();
    }
  }

  // Keyboard and screen reader users can tab to links in the cut-off part,
  // so expand the content rather than leave the focus on something hidden.
  reveal(event) {
    if (this.expanded) return;
    const content = this.contentTarget;
    content.scrollTop = 0; // the browser scrolls the clipped content to the focused link
    if (event.target.getBoundingClientRect().bottom > content.getBoundingClientRect().bottom) {
      this.setExpanded(true);
    }
  }

  setExpanded(expanded) {
    this.expanded = expanded;
    this.contentTarget.classList.toggle("collapsed", !expanded);
    this.buttonTarget.textContent = expanded ? this.lessValue : this.moreValue;
    this.buttonTarget.setAttribute("aria-expanded", expanded);
  }
}
