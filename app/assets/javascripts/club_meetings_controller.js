class ClubMeetingsController extends Controller {
  static targets = ["list", "template", "count"]

  connect() {
    this.nextIndex = Date.now();
  }

  add() {
    const index = this.nextIndex++;
    this.listTarget.insertAdjacentHTML("beforeend", this.templateTarget.innerHTML.replace(/NEW_RECORD/g, index));
  }

  updateCount(event) {
    const input = event.target;
    const count = input.closest(".club-meeting-fields").querySelector("[data-club-meetings-target='count']");
    count.textContent = `${input.value.length}/${input.maxLength}`;
  }

  remove(event) {
    const row = event.currentTarget.closest(".club-meeting-fields");
    if (row.dataset.newRecord === "true") {
      row.remove();
    } else {
      row.querySelector("input[name$='[_destroy]']").value = "1";
      row.classList.add("hidden");
    }
  }
}
