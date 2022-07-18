import data from "./data.json";
import Chart from "chart.js/auto";

function newShade(hexColor, magnitude) {
  hexColor = hexColor.replace(`#`, ``);
  if (hexColor.length === 6) {
    const decimalColor = parseInt(hexColor, 16);
    let r = (decimalColor >> 16) + magnitude;
    r > 255 && (r = 255);
    r < 0 && (r = 0);
    let g = (decimalColor & 0x0000ff) + magnitude;
    g > 255 && (g = 255);
    g < 0 && (g = 0);
    let b = ((decimalColor >> 8) & 0x00ff) + magnitude;
    b > 255 && (b = 255);
    b < 0 && (b = 0);
    return `#${(g | (b << 8) | (r << 16)).toString(16)}`;
  } else {
    return hexColor;
  }
}

const colors = ["#b3cde3", "#ccebc5", "#decbe4", "#fed9a6", "#ffffcc"];
const max = Math.ceil(data.max) + 20;
delete data.max;
for (g in data) {
  const ctx = document.getElementById(`${g}-chart`).getContext("2d");
  options = {
    animation: false,
    elements: {
      bar: {
        borderWidth: 1.5,
      },
    },
    responsive: true,
    scales: {
      y: {
        beginAtZero: true,
        min: 0,
        suggestedMax: max,
        title: { text: "seconds", display: true },
      },
    },
    plugins: { legend: false },
  };

  data[g].datasets[0].backgroundColor = [];
  data[g].datasets[0].borderColor = [];
  data[g].datasets[0].data.forEach(function (dataset, i) {
    data[g].datasets[0].backgroundColor.push(colors[i]);
    data[g].datasets[0].borderColor.push(newShade(colors[i], -50));
  });
  if (g === "install") {
    data[g].datasets[1].backgroundColor = [];
    data[g].datasets[1].borderColor = [];
    data[g].datasets[1].data.forEach(function (dataset, i) {
      data[g].datasets[1].backgroundColor.push(newShade(colors[i], -30));
      data[g].datasets[1].borderColor.push(newShade(colors[i], -65));
    });
    options.scales.x = {
      ticks: {
        callback: function (value, index, ticks) {
          return [data[g].labels[index], "cold / warm"];
        },
      },
    };
  }

  new Chart(ctx, {
    type: "bar",
    data: data[g],
    options: options,
  });
}
