var chartInterval = "second";
var chartAmount = 300;
var chartsCallbacks = [];

function updateCharts() {
  for (const cb of chartsCallbacks) {
    cb();
  }
}

function lineChart(id, title, color, units, labels, datapoints) {
  var ctx = document.getElementById("sensor"+id);
  var data = {
    labels: labels,
    datasets: [{
      label: title,
      backgroundColor: color,
      borderColor: color,
      lineTension: 0,
      data: datapoints,
      fill: false,
      }],
    };
  var options = {
				responsive: true,
        maintainAspectRatio: true,
				title: {
					display: true,
					text: title
				},
				tooltips: {
					mode: 'index',
          intersect: false,
				},
				hover: {
					mode: 'nearest',
					intersect: true
				},
        legend: {
          display: false,
        },
        scales: {
					xAxes: [{
            type: 'time',
            time: {
              parser: 'HH:mm',
              tooltipFormat: 'HH:mm',
              displayFormats: {
                  'millisecond': 'HH:mm',
                  'second': 'HH:mm',
                  'minute': 'HH:mm',
                  'hour': 'HH:mm'
              },
            },
					}],
					yAxes: [{
						display: true,
						scaleLabel: {
							display: true,
							labelString: units
						}
					}]
				}
			};
  var myChart = new Chart(ctx, {
    type: 'line',
    data: data,
    options: options
  });
  var getData = function() {
    $.ajax({
      url: '/api/sensor?sid=' + id + '&interval=' + chartInterval + '&count=' + chartAmount,
      success: function(data) {
        // process your data to pull out what you plan to use to update the chart
        // e.g. new label and a new data point

        // add new label and data point to chart's underlying data structures
        myChart.data.labels = data.time;
        myChart.data.datasets[0].data = data.values;

        // re-render the chart
        myChart.update();
      }
    });
  };
  setInterval(getData, 5000);
  chartsCallbacks.push(getData);
}

function setSeconds() {
  chartInterval = "second";
  chartAmount = 300;
  updateCharts();
}

function setMinutes() {
  chartInterval = "minute";
  chartAmount = 60;
  updateCharts();
}

function setHours() {
  chartInterval = "hour";
  chartAmount = 24;
  updateCharts();
}

function setDays() {
  chartInterval = "day";
  chartAmount = 60;
  updateCharts();
}
