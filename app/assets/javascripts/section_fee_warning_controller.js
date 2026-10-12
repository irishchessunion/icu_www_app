// Stimulus controller for the form that moves an event entry to another
// section (admin/items/edit). Each warning is for one section and is only
// shown while that section is the one selected.
class SectionFeeWarningController extends Controller {
  static targets = ["warning"]

  connect() {
    this.update();
  }

  update() {
    const select = this.element.querySelector("select[name='item[section]']");
    const section = select ? select.value : null;
    this.warningTargets.forEach((warning) => {
      warning.classList.toggle("hidden", warning.dataset.section !== section);
    });
  }
}
