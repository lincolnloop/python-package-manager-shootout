import data from "./data.json";
import Chart from "chart.js/auto";
import annotationPlugin from "chartjs-plugin-annotation";

Chart.register(annotationPlugin);

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

const colors = [
  "#8dd3c7",
  "#ffffb3",
  "#bebada",
  "#fb8072",
  "#80b1d3",
  "#fdb462",
  "#b3de69",
  "#fccde5",
  "#d9d9d9",
  "#bc80bd",
  "#ccebc5",
  "#ffed6f",
];

// https://github.com/chartjs/chartjs-plugin-annotation/blob/752f7e0e6b83f7e606a87ed63720e014f91dd276/docs/samples/line/datasetBars.md?plain=1#L125-L136
function indexToMin(index, datasetCount, datasetIndex) {
  if (datasetCount === 2 && datasetIndex === 1) {
    return index + 0.04;
  }
  return index - 0.36;
}

function indexToMax(index, datasetCount, datasetIndex) {
  if (datasetCount === 2 && datasetIndex === 0) {
    return index - 0.04;
  }
  return index + 0.36;
}

function indexToMid(index, datasetCount, datasetIndex) {
  if (datasetCount === 2) {
    if (datasetIndex === 0) {
      return index - 0.2;
    }
    return index + 0.2;
  }
  return index;
}

const max = Math.ceil(data.max) + 10;
const stdevLineColor = "#888888";
delete data.max;
for (const graph in data) {
  const ctx = document.getElementById(`${graph}-chart`).getContext("2d");
  const options = {
    animation: false,
    elements: {
      bar: {
        borderWidth: 1.5,
      },
    },
    parsing: {
      xAxisKey: "id",
      yAxisKey: "avg",
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
    plugins: {
      legend: false,
      tooltip: {
        callbacks: {
          label: function (context) {
            return [
              `avg: ${context.raw.avg}`,
              `max: ${context.raw.max}`,
              `min: ${context.raw.min}`,
            ];
          },
        },
      },
    },
  };

  data[graph].datasets[0].backgroundColor = [];
  data[graph].datasets[0].borderColor = [];
  data[graph].datasets[0].data.forEach(function (dataset, i) {
    data[graph].datasets[0].backgroundColor.push(colors[i]);
    data[graph].datasets[0].borderColor.push(newShade(colors[i], -50));
  });
  if (data[graph].datasets.length > 1) {
    data[graph].datasets[1].backgroundColor = [];
    data[graph].datasets[1].borderColor = [];
    data[graph].datasets[1].data.forEach(function (dataset, i) {
      data[graph].datasets[1].backgroundColor.push(newShade(colors[i], -30));
      data[graph].datasets[1].borderColor.push(newShade(colors[i], -65));
    });
    options.scales.x = {
      ticks: {
        callback: function (value, index, ticks) {
          return [data[graph].labels[index], "cold / warm"];
        },
      },
    };
  }

  // TODO: pass in max/min values to show variation in results
  options.plugins.annotation = { annotations: {} };
  for (let idx = 0; idx < data[graph].datasets.length; idx++) {
    for (let idx2 = 0; idx2 < data[graph].datasets[idx].data.length; idx2++) {
      options.plugins.annotation.annotations[`annotations-min-${idx}-${idx2}`] =
        {
          type: "line",
          borderColor: stdevLineColor,
          borderWidth: 1.5,
          xMax: indexToMax(idx2, data[graph].datasets.length, idx) - 0.25,
          xMin: indexToMin(idx2, data[graph].datasets.length, idx) + 0.25,
          xScaleID: "x",
          // random number between 0 and 100
          yMax: data[graph].datasets[idx].data[idx2].min,
          yMin: data[graph].datasets[idx].data[idx2].min,
          yScaleID: "y",
        };
      options.plugins.annotation.annotations[`annotations-max-${idx}-${idx2}`] =
        {
          type: "line",
          borderColor: stdevLineColor,
          borderWidth: 1.5,
          xMax: indexToMax(idx2, data[graph].datasets.length, idx) - 0.25,
          xMin: indexToMin(idx2, data[graph].datasets.length, idx) + 0.25,
          xScaleID: "x",
          // random number between 0 and 100
          yMax: data[graph].datasets[idx].data[idx2].max,
          yMin: data[graph].datasets[idx].data[idx2].max,
          yScaleID: "y",
        };
      const midLine = indexToMid(idx2, data[graph].datasets.length, idx);
      options.plugins.annotation.annotations[
        `annotations-vert-${idx}-${idx2}`
      ] = {
        type: "line",
        borderColor: stdevLineColor,
        borderWidth: 1.5,
        xMax: midLine,
        xMin: midLine,
        xScaleID: "x",
        // random number between 0 and 100
        yMax: data[graph].datasets[idx].data[idx2].max,
        yMin: data[graph].datasets[idx].data[idx2].min,
        yScaleID: "y",
      };
    }
  }
  new Chart(ctx, {
    type: "bar",
    data: data[graph],
    options: options,
  });
}
