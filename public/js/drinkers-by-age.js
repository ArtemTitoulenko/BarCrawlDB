(function (){
  values = drinker_age_dist

  var formatCount = d3.format("d");

  var margin = {top: 10, right: 50, bottom: 30, left: 50},
    width = 1200 - margin.left - margin.right,
    height = 500 - margin.top - margin.bottom;

  var x = d3.scale.linear()
    .domain([21,100])
    .range([0, width])

  var y = d3.scale.linear()
    .domain([0, d3.max(values)])
    .range([height - margin.bottom, 0])

  var xAxis = d3.svg.axis()
    .scale(x)
    .orient("bottom");

  var yAxis = d3.svg.axis()
    .scale(y)
    .orient('left')

  var svg = d3.select('.drinker-hist').append('svg')
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
  .append('g')
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

  var bar = svg.selectAll(".bar")
    .data(values)
  .enter().append("g")
    .attr("class", "bar")
    .attr('transform', function (d, i) { return "translate(" + x(i+21) + "," + y(d) +")"; })

  bar.append('rect')
    .attr('width', width / values.length - 1)
    .attr('height', function (d) { return height - y(d) })

  svg.append("g")
    .attr("class", "x axis")
    .attr("transform", "translate(0," + height + ")")
    .call(xAxis);

  svg.append("g")
    .attr("class", "y axis")
    .attr("transform", "translate(0, 0)")
    .call(yAxis)
})()
