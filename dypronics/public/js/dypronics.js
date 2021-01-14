function getRandomInt(max) {
  return Math.floor(Math.random() * Math.floor(max));
}

function lineChart(name, title) {
  var ctx = document.getElementById(name);
  var datapoints = [0, 20, 20, 60, 60, 120, NaN, 180, 120, 125, 105, 110, 170];
  var data = {
    labels: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'],
    datasets: [{
      label: title,
      backgroundColor: '#cc2020',
      borderColor: '#cc2020',
      lineTension: 0,
      data: datapoints,
      fill: false,
      }],
    };
  var options = {
				responsive: true,
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
        scales: {
					xAxes: [{
						display: true,
						scaleLabel: {
							display: true
						}
					}],
					yAxes: [{
						display: true,
						scaleLabel: {
							display: true,
							labelString: 'Value'
						},
						ticks: {
							suggestedMin: -10,
							suggestedMax: 200,
						}
					}]
				}
			};
  var myChart = new Chart(ctx, {
    type: 'line',
    data: data,
    options: options
  });
}