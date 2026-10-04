// Stimulus controller that caps the height of long content (e.g. news items
// on the home page) and adds a "Show more" / "Show less" toggle. The toggle
// only appears when the content is actually taller than the cap, which is
// rechecked as images load and when the window is resized. Without JS the
// content is shown in full. The toggle is a plain link under the content,
// like "Show more" on long posts on X.
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
    this.expanded = !this.expanded;
    this.contentTarget.classList.toggle("collapsed", !this.expanded);
    this.buttonTarget.textContent = this.expanded ? this.lessValue : this.moreValue;
    this.buttonTarget.setAttribute("aria-expanded", this.expanded);
    if (!this.expanded) {
      if (this.element.getBoundingClientRect().top < 0) this.element.scrollIntoView();
      this.update();
    }
  }
}
