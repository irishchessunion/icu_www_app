class ClubsDirectoryController extends Controller {
  static targets = ["form", "content", "map", "markers", "results", "list", "count", "empty"]
  static values = { marker: String, count: String }

  connect() {
    this.mobile = window.matchMedia("(max-width: 768px)");
    this.markerData = JSON.parse(this.markersTarget.textContent);
    this.mapMarkers = [];
    document.body.classList.add("clubs-directory-page");
    this.wheel = this.scrollList.bind(this);
    document.addEventListener("wheel", this.wheel, { passive: false });
    this.observer = new ResizeObserver(() => this.resize());
    this.observer.observe(this.element);
    this.observer.observe(document.querySelector("body > header"));
    this.refresh();
  }

  disconnect() {
    clearTimeout(this.timer);
    this.observer.disconnect();
    document.removeEventListener("wheel", this.wheel);
    document.body.classList.remove("clubs-directory-page");
    if (this.map) this.map.remove();
  }

  typing(event) {
    if (event.target.name !== "search") return;
    clearTimeout(this.timer);
    this.timer = setTimeout(() => this.formTarget.requestSubmit(), 300);
  }

  change(event) {
    if (event.target.name === "search") return;
    clearTimeout(this.timer);
    this.formTarget.requestSubmit();
  }

  submitting() {
    clearTimeout(this.timer);
    const params = new URLSearchParams(new FormData(this.formTarget));
    const county = params.get("county");
    const path = county ? `${this.formTarget.action}/county/${encodeURIComponent(county)}` : this.formTarget.action;
    params.delete("county");
    if (params.get("audience") === "all") params.delete("audience");
    Array.from(params).forEach(([key, value]) => { if (!value) params.delete(key); });
    const url = new URL(path);
    url.search = params.toString();
    window.history.replaceState(window.history.state, "", url);
  }

  clear(event) {
    event.preventDefault();
    this.formTarget.querySelectorAll("input[type='search'], select[name='county'], select[name='day_of_week']").forEach(input => { input.value = ""; });
    this.formTarget.querySelectorAll("input[type='checkbox']").forEach(input => { input.checked = false; });
    this.formTarget.querySelector("input[name='audience'][value='all']").checked = true;
    this.formTarget.requestSubmit();
  }

  refresh() {
    this.matchingIds = new Set(JSON.parse(this.resultsTarget.textContent));
    const count = this.listTarget.querySelectorAll("[data-club-id]").length;
    this.countTarget.textContent = this.countValue.replace("%{count}", count);
    this.emptyTarget.classList.toggle("hidden", count > 0);
    this.listTarget.scrollTop = 0;
    this.resize();
  }

  resize() {
    this.element.style.setProperty("--clubs-content-height", `${Math.max(0, window.innerHeight - this.contentTarget.getBoundingClientRect().top - 15)}px`);
    if (!this.mobile.matches || this.element.classList.contains("clubs-show-map")) this.ensureMap();
    if (this.map) {
      this.map.resize();
      this.updateMap();
    }
  }

  scrollList(event) {
    if (this.mobile.matches || event.ctrlKey || event.target.closest("select, textarea, .maplibregl-popup")) return;
    // Let the scroll area handle its own wheel events, including trackpad momentum.
    if (this.listTarget.contains(event.target)) return;
    event.preventDefault();
    const factor = event.deltaMode === 1 ? 20 : event.deltaMode === 2 ? this.listTarget.clientHeight : 1;
    this.listTarget.scrollTop += event.deltaY * factor;
  }

  showList(event) {
    event.preventDefault();
    this.selectTab(false);
  }

  showMap(event) {
    if (event) event.preventDefault();
    this.selectTab(true);
    this.resize();
  }

  selectTab(map) {
    this.element.classList.toggle("clubs-show-map", map);
    ["list", "map"].forEach(tab => {
      const link = this.element.querySelector(`#clubs-${tab}-tab`);
      const selected = (tab === "map") === map;
      link.setAttribute("aria-selected", selected);
      link.parentElement.classList.toggle("active", selected);
    });
  }

  ensureMap() {
    if (this.map) return;
    this.map = ICU.Maps.init(this.mapTarget, { markers: [], fit: false });
    if (!this.map) return;
    this.map.scrollZoom.disable();
    this.mapMarkers = this.markerData.map(data => {
      const element = document.createElement("img");
      element.src = this.markerValue;
      element.width = 20;
      element.height = 25;
      element.alt = data.title;
      element.style.cursor = "pointer";
      // MapLibre manages opacity on the marker wrapper itself.
      const wrapper = document.createElement("div");
      wrapper.appendChild(element);
      const marker = new maplibregl.Marker({ element: wrapper })
        .setLngLat([data.lng, data.lat])
        .setPopup(new maplibregl.Popup().setHTML(data.popupHtml))
        .addTo(this.map);
      return { data, marker, element };
    });
    this.map.on("load", () => this.updateMap());
  }

  updateMap() {
    const includeInactive = this.formTarget.querySelector("[name='include_inactive']:checked");
    const selected = [];
    this.mapMarkers.forEach(({ data, marker, element }) => {
      const visible = data.active || includeInactive;
      const matching = this.matchingIds.has(data.id);
      marker.getElement().classList.toggle("hidden", !visible);
      element.style.opacity = matching ? "1" : "0.6";
      if (!visible && marker.getPopup().isOpen()) marker.togglePopup();
      if (visible && matching) selected.push([data.lng, data.lat]);
    });

    const filtered = this.formTarget.querySelector("[name='search']").value.trim() || this.formTarget.querySelector("[name='county']").value || this.formTarget.querySelector("[name='day_of_week']").value || this.formTarget.querySelector("[name='audience']:checked").value !== "all";
    const points = filtered && selected.length ? selected : [[-10.8, 51.3], [-5.3, 55.5]];
    const bounds = points.reduce((bounds, point) => bounds.extend(point), new maplibregl.LngLatBounds());
    this.map.fitBounds(bounds, { padding: 30, maxZoom: 12, duration: 0 });
  }
}
