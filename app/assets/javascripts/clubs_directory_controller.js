class ClubsDirectoryController extends Controller {
  static targets = ["form", "content", "controls", "map", "markers", "results", "list", "count", "empty", "radius", "geolocation", "locate", "locationStatus"]
  static values = { marker: String, highlightedMarker: String, countOne: String, countOther: String, locationError: String }

  connect() {
    this.mobile = window.matchMedia("(max-width: 768px)");
    this.markerData = JSON.parse(this.markersTarget.textContent);
    this.mapMarkers = [];
    if (typeof window.HTMLGeolocationElement === "function") {
      this.geolocationTarget.classList.add("btn", "btn-pastel-info");
    }
    document.body.classList.add("clubs-directory-page");
    this.wheel = this.scrollList.bind(this);
    this.contentTarget.addEventListener("wheel", this.wheel, { passive: false });
    this.observer = new ResizeObserver(() => this.resize());
    this.observer.observe(this.element);
    const header = document.querySelector("body > header");
    if (header) this.observer.observe(header);
    this.refresh();
  }

  disconnect() {
    clearTimeout(this.timer);
    this.observer.disconnect();
    this.contentTarget.removeEventListener("wheel", this.wheel);
    document.body.classList.remove("clubs-directory-page", "clubs-page-scroll");
    if (this.map) this.map.remove();
  }

  typing(event) {
    if (event.target.name !== "search") return;
    clearTimeout(this.timer);
    this.timer = setTimeout(() => this.formTarget.requestSubmit(), 300);
  }

  change(event) {
    if (event.target.name === "search") return;
    if (event.target.name === "radius") {
      if (this.position) this.refresh();
    } else {
      clearTimeout(this.timer);
      this.formTarget.requestSubmit();
    }
  }

  submitting() {
    clearTimeout(this.timer);
    const params = new URLSearchParams(new FormData(this.formTarget));
    const county = params.get("county");
    const path = county ? `${this.formTarget.action}/county/${encodeURIComponent(county)}` : this.formTarget.action;
    params.delete("county");
    params.delete("radius");
    if (params.get("audience") === "all") params.delete("audience");
    Array.from(params).forEach(([key, value]) => { if (!value) params.delete(key); });
    const url = new URL(path);
    url.search = params.toString();
    window.history.replaceState(window.history.state, "", url);
  }

  clear(event) {
    event.preventDefault();
    this.position = null;
    this.locationStatusTarget.textContent = "";
    this.formTarget.querySelectorAll("input[type='search'], select[name='county'], select[name='day_of_week']").forEach(input => { input.value = ""; });
    this.formTarget.querySelectorAll("input[type='checkbox']").forEach(input => { input.checked = false; });
    this.formTarget.querySelector("input[name='audience'][value='all']").checked = true;
    this.radiusTarget.selectedIndex = 0;
    this.formTarget.requestSubmit();
  }

  refresh() {
    this.mapMarkers.forEach(entry => {
      entry.highlighted = false;
      entry.element.src = this.markerValue;
    });
    this.matchingIds = new Set(JSON.parse(this.resultsTarget.textContent));
    let count = 0;
    this.listTarget.querySelectorAll("[data-club-id]").forEach(row => {
      const visible = this.inRadius(row.dataset);
      row.classList.toggle("hidden", !visible);
      if (visible) count++;
    });
    const countMessage = count === 1 ? this.countOneValue : this.countOtherValue;
    this.countTarget.textContent = countMessage.replace("%{count}", count);
    this.emptyTarget.classList.toggle("hidden", count > 0);
    this.listTarget.scrollTop = 0;
    this.mapNeedsUpdate = true;
    this.resize();
  }

  resize() {
    // Use the document position so scrolling the fallback page does not change its layout mode.
    const height = Math.max(0, window.innerHeight - (this.contentTarget.getBoundingClientRect().top + window.scrollY) - 15);
    const result = this.listTarget.querySelector("[data-club-id]:not(.hidden)") || this.emptyTarget;
    const minimumHeight = this.controlsTarget.getBoundingClientRect().height + parseFloat(getComputedStyle(this.contentTarget).rowGap) + result.getBoundingClientRect().height;
    this.pageScroll = !this.mobile.matches && height < minimumHeight;
    document.body.classList.toggle("clubs-page-scroll", this.pageScroll);
    this.element.style.setProperty("--clubs-content-height", `${height}px`);
    const mapVisible = !this.mobile.matches || this.element.classList.contains("clubs-show-map");
    if (mapVisible) this.ensureMap();
    if (this.map && mapVisible) {
      this.map.resize();
      // Defer changed results until the map is visible; layout changes alone keep its camera.
      if (this.mapNeedsUpdate) {
        this.updateMap();
        this.mapNeedsUpdate = false;
      }
    }
  }

  scrollList(event) {
    if (this.mobile.matches || this.pageScroll || event.ctrlKey || event.target.closest("select, textarea, .maplibregl-popup")) return;
    // Let the scroll area handle its own wheel events, including trackpad momentum.
    if (this.listTarget.contains(event.target)) return;
    event.preventDefault();
    const factor = event.deltaMode === 1 ? 20 : event.deltaMode === 2 ? this.listTarget.clientHeight : 1;
    this.listTarget.scrollTop += event.deltaY * factor;
  }

  highlightMarker(event) {
    const entry = this.mapMarkers.find(({ data }) => data.id === Number(event.currentTarget.dataset.clubId));
    if (entry) {
      entry.highlighted = event.type === "mouseenter";
      entry.element.src = entry.highlighted ? this.highlightedMarkerValue : this.markerValue;
      entry.marker.getElement().style.zIndex = entry.highlighted ? "2" : this.matchingIds.has(entry.data.id) ? "1" : "0";
    }
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

  locate() {
    if (!navigator.geolocation) return this.locationFailed();
    this.locateTarget.disabled = true;
    navigator.geolocation.getCurrentPosition(
      position => { this.locateTarget.disabled = false; this.usePosition(position); },
      () => { this.locateTarget.disabled = false; this.locationFailed(); },
      { timeout: 15000, maximumAge: 60000 }
    );
  }

  located(event) {
    if (event.currentTarget.position) this.usePosition(event.currentTarget.position);
    else if (event.currentTarget.error) this.locationFailed();
  }

  usePosition(position) {
    this.position = new maplibregl.LngLat(position.coords.longitude, position.coords.latitude);
    this.locationStatusTarget.textContent = "";
    const clubs = Array.from(this.listTarget.querySelectorAll("[data-club-id]"));
    while (!clubs.some(club => this.inRadius(club.dataset)) && this.radiusTarget.selectedIndex < this.radiusTarget.options.length - 1) {
      this.radiusTarget.selectedIndex++;
    }
    if (this.mobile.matches) this.showMap();
    this.refresh();
  }

  locationFailed() {
    this.locationStatusTarget.textContent = this.locationErrorValue;
    this.locationStatusTarget.classList.remove("sr-only");
    this.locationStatusTarget.classList.add("text-danger");
  }

  inRadius(point) {
    if (!this.position) return true;
    if (point.lat == null || point.lng == null || point.lat === "" || point.lng === "") return false;
    return this.position.distanceTo(new maplibregl.LngLat(Number(point.lng), Number(point.lat))) <= Number(this.radiusTarget.value) * 1000;
  }

  ensureMap() {
    if (this.map) return;
    this.map = ICU.Maps.init(this.mapTarget, { markers: [], fit: false });
    if (!this.map) return;
    this.mapNeedsUpdate = true;
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
      wrapper.dataset.clubId = data.id;
      wrapper.dataset.action = "mouseenter->clubs-directory#highlightMarker mouseleave->clubs-directory#highlightMarker";
      wrapper.appendChild(element);
      const marker = new maplibregl.Marker({ element: wrapper })
        .setLngLat([data.lng, data.lat])
        .setPopup(new maplibregl.Popup().setHTML(data.popupHtml))
        .addTo(this.map);
      return { data, marker, element };
    });
    this.map.on("load", () => this.updateMap(false));
  }

  updateMap(fit = true) {
    const includeInactive = this.formTarget.querySelector("[name='include_inactive']:checked");
    const selected = [];
    this.mapMarkers.forEach(({ data, marker, element, highlighted }) => {
      const visible = (data.active || includeInactive) && this.inRadius(data);
      const matching = this.matchingIds.has(data.id);
      marker.getElement().classList.toggle("hidden", !visible);
      marker.getElement().style.zIndex = highlighted ? "2" : matching ? "1" : "0";
      element.style.opacity = matching ? "1" : "0.4";
      element.style.filter = matching ? "none" : "sepia(1)";
      if (!visible && marker.getPopup().isOpen()) marker.togglePopup();
      if (visible && matching) selected.push([data.lng, data.lat]);
    });

    const circle = this.position ? this.radiusCircle() : [];
    if (this.map.isStyleLoaded()) {
      const geojson = { type: "FeatureCollection", features: circle.length ? [{ type: "Feature", properties: {}, geometry: { type: "Polygon", coordinates: [circle] } }] : [] };
      if (this.map.getSource("club-radius")) {
        this.map.getSource("club-radius").setData(geojson);
      } else {
        this.map.addSource("club-radius", { type: "geojson", data: geojson });
        const color = getComputedStyle(this.element).getPropertyValue("--brand-info").trim();
        this.map.addLayer({ id: "club-radius-fill", type: "fill", source: "club-radius", paint: { "fill-color": color, "fill-opacity": 0.15 } });
        this.map.addLayer({ id: "club-radius-line", type: "line", source: "club-radius", paint: { "line-color": color, "line-width": 2 } });
      }
    }

    if (!fit) return;
    const filtered = this.formTarget.querySelector("[name='search']").value.trim() || this.formTarget.querySelector("[name='county']").value || this.formTarget.querySelector("[name='day_of_week']").value || this.formTarget.querySelector("[name='audience']:checked").value !== "all";
    const points = circle.length ? circle : filtered && selected.length ? selected : [[-10.8, 51.3], [-5.3, 55.5]];
    const bounds = points.reduce((bounds, point) => bounds.extend(point), new maplibregl.LngLatBounds());
    this.map.fitBounds(bounds, { padding: 30, maxZoom: 12, duration: 0 });
  }

  radiusCircle() {
    const lat = this.position.lat * Math.PI / 180;
    const lng = this.position.lng * Math.PI / 180;
    const distance = Number(this.radiusTarget.value) / 6371;
    const points = [];
    for (let i = 0; i <= 64; i++) {
      const bearing = i * 2 * Math.PI / 64;
      const y = Math.asin(Math.sin(lat) * Math.cos(distance) + Math.cos(lat) * Math.sin(distance) * Math.cos(bearing));
      const x = lng + Math.atan2(Math.sin(bearing) * Math.sin(distance) * Math.cos(lat), Math.cos(distance) - Math.sin(lat) * Math.sin(y));
      points.push([x * 180 / Math.PI, y * 180 / Math.PI]);
    }
    return points;
  }
}
