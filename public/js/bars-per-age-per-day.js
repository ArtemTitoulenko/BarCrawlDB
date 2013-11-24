(function (){
  values = bars_per_age_per_day[0]

  var formatCount = d3.format("d");

  var margin = {top: 10, right: 50, bottom: 30, left: 50},
    width = 1200 - margin.left - margin.right,
    height = 500 - margin.top - margin.bottom;

  var x = d3.scale.linear()
    .domain([21,100])
    .range([0, width])

  var y = d3.scale.linear()
    .domain([0, d3.max(values, function (d) { return d.num_bars })])
    .range([height - margin.bottom, 0])

  var xAxis = d3.svg.axis()
    .scale(x)
    .orient("bottom");

  var yAxis = d3.svg.axis()
    .scale(y)
    .orient('left')

  var svg = d3.select('.bar-visit-hist').append('svg')
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
  .append('g')
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

  svg.append("g")
    .attr("class", "x axis")
    .attr("transform", "translate(0," + height + ")")
    .call(xAxis);

  svg.append("g")
    .attr("class", "y axis")
    .attr("transform", "translate(0, 0)")
    .call(yAxis)

  var refresh_graph = function () {
    y.domain([0, d3.max(values, function (d) { return d.num_bars })])

    var bar = svg.selectAll(".bar")
      .data(values)
    .enter().append("g")
      .attr("class", "bar")
      .attr('transform', function (d, i) { return "translate(" + x(i+21) + "," + y(d.num_bars) +")"; })

    bar.append('rect')
      .attr('width', width / values.length - 1)
      .attr('height', function (d) { return height - y(d.num_bars) })

    svg.selectAll(".bar").data(values).enter()
      .select("g")
      .attr("class", "bar")
      .attr('transform', function (d, i) { return "translate(" + x(i+21) + "," + y(d.num_bars) +")"; })
  }

  d3.selectAll('.day-ctl')
    .on('click', function () {
      var index = this.getAttribute('data_day')

      var old_selected = d3.select('.bar-hist-controls .active')[0][0]
      old_selected.classList.remove("active")
      this.classList.add("active")

      values = bars_per_age_per_day[index]
      refresh_graph()
    })

  refresh_graph()
})()
