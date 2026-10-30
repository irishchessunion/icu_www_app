class OverviewChartController extends Controller {
  static targets = ["period", "breakdown", "chart", "status"]
  static values = { url: String, title: String }

  connect() {
    this.cache = new Map();
    this.updates = Promise.resolve();
    this.version = 0;
    this.load();
  }

  disconnect() {
    this.version++;
    if (this.request) this.request.abort();
    this.chartData = null;
    if (this.chart) this.chart.destroy();
    this.chart = null;
  }

  async load() {
    const version = ++this.version;
    const period = this.periodTarget.querySelector("input:checked").value;
    if (this.request) this.request.abort();
    this.chartData = null;
    this.setStatus("Loading chart...");
    this.element.setAttribute("aria-busy", "true");

    try {
      if (!this.cache.has(period)) {
        this.request = new AbortController();
        const url = new URL(this.urlValue, window.location.href);
        url.searchParams.set("period", period);
        const response = await window.fetch(url, { headers: { Accept: "application/json" }, signal: this.request.signal });
        if (!response.ok) throw new Error("Unable to load chart data");
        this.cache.set(period, await response.json());
      }
      if (version !== this.version) return;

      this.chartData = this.cache.get(period);
      const series = Object.values(this.chartData.series)[0];
      const hasData = series.some(group => group.data.some(value => value > 0));
      this.setStatus(hasData ? "" : "No data for this period.");
      await this.refresh();
    } catch (error) {
      if (version === this.version && error.name !== "AbortError") this.showError(error);
    } finally {
      if (version === this.version) this.element.setAttribute("aria-busy", "false");
    }
  }

  async refresh() {
    this.updates = this.updates.catch(() => {}).then(() => {
      if (!this.chartData || !this.element.isConnected) return;

      const breakdown = this.breakdownTarget.querySelector("input:checked").value;
      const options = {
        series: structuredClone(this.chartData.series[breakdown]),
        xaxis: { categories: this.chartData.categories.slice() }
      };
      if (this.chart) return this.chart.updateOptions(options, false, false);

      this.chart = new ApexCharts(this.chartTarget, { ...this.chartOptions(), ...options });
      return this.chart.render();
    });

    try {
      await this.updates;
    } catch (error) {
      if (this.element.isConnected) this.showError(error);
    }
  }

  chartOptions() {
    const style = getComputedStyle(this.element);
    const color = name => style.getPropertyValue(name).trim();
    const colors = ["--brand-info", "--brand-success", "--brand-warning", "--brand-danger", "--brand-primary", "--gray-dark", "--gray-light", "--gray-darker", "--gray"].map(color);

    return {
      chart: {
        type: "bar",
        stacked: true,
        height: 360,
        fontFamily: style.fontFamily,
        foreColor: style.color,
        background: getComputedStyle(document.body).backgroundColor,
        animations: { enabled: false },
        toolbar: { show: false },
        zoom: { enabled: false }
      },
      colors,
      plotOptions: { bar: { horizontal: false, columnWidth: "65%" } },
      dataLabels: { enabled: false },
      stroke: { width: 0 },
      yaxis: { opposite: true, min: 0, decimalsInFloat: 0, title: { text: this.titleValue } },
      grid: { borderColor: color("--gray-light") },
      legend: { position: "bottom" },
      tooltip: { shared: true, intersect: false, custom: options => this.tooltipContent(options) }
    };
  }

  tooltipContent({ series, dataPointIndex, w }) {
    const tooltip = document.createElement("div");
    const title = document.createElement("div");
    title.className = "apexcharts-tooltip-title";
    title.textContent = w.config.xaxis.categories[dataPointIndex];
    tooltip.append(title);

    let total = 0;
    series.forEach((values, index) => {
      if (w.globals.collapsedSeriesIndices.includes(index)) return;

      const value = values[dataPointIndex] ?? 0;
      total += value;
      tooltip.append(this.tooltipRow(w.globals.seriesNames[index], value, w.globals.colors[index]));
    });

    const separator = document.createElement("hr");
    separator.className = "no-margin";
    tooltip.append(separator, this.tooltipRow("Total", total));
    return tooltip;
  }

  tooltipRow(name, value, color) {
    const row = document.createElement("div");
    row.className = "apexcharts-custom-tooltip";
    if (color) {
      const marker = document.createElement("span");
      marker.className = "apexcharts-tooltip-marker";
      marker.setAttribute("aria-hidden", "true");
      const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
      svg.setAttribute("viewBox", "0 0 12 12");
      const circle = document.createElementNS(svg.namespaceURI, "circle");
      Object.entries({ cx: 6, cy: 6, r: 5, fill: color }).forEach(([key, value]) => circle.setAttribute(key, value));
      svg.append(circle);
      marker.append(svg);
      row.append(marker);
    }

    const label = document.createElement("span");
    label.className = "apexcharts-tooltip-text-y-label";
    label.textContent = `${name}: `;
    const amount = document.createElement("span");
    amount.className = "apexcharts-tooltip-text-y-value";
    amount.textContent = value.toLocaleString("en-IE");
    row.append(label, amount);
    return row;
  }

  setStatus(message, error = false) {
    this.statusTarget.textContent = message;
    this.statusTarget.classList.toggle("text-danger", error);
    this.statusTarget.classList.toggle("text-muted", !error);
    this.statusTarget.classList.toggle("hidden", !message);
  }

  showError(error) {
    console.error("Unable to load overview chart", error);
    this.setStatus("Unable to load chart. Please reload the page to try again.", true);
  }
}
