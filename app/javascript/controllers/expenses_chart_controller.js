import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { data: Array }

  connect() {
    const labels = this.dataValue.map(d => d.day)
    const amounts = this.dataValue.map(d => d.amount)

    this.chart = new window.Chart(this.element, {
      type: "line",
      data: {
        labels,
        datasets: [{
          label: "Gastos",
          data: amounts,
          borderColor: "#6366f1",
          backgroundColor: "rgba(99, 102, 241, 0.1)",
          borderWidth: 2,
          pointRadius: 3,
          pointBackgroundColor: "#6366f1",
          fill: true,
          tension: 0.3
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: {
            callbacks: {
              label: ctx => ` $${ctx.parsed.y.toLocaleString("es-MX", { minimumFractionDigits: 2 })}`
            }
          }
        },
        scales: {
          x: {
            title: { display: true, text: "Día del mes" },
            grid: { display: false }
          },
          y: {
            title: { display: true, text: "Monto ($)" },
            beginAtZero: true,
            ticks: {
              callback: val => `$${val.toLocaleString("es-MX")}`
            }
          }
        }
      }
    })
  }

  disconnect() {
    this.chart?.destroy()
  }
}
