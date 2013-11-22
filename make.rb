require 'json'
require 'pry'

require './classes'

RAD_PER_DEG = 0.017453293  #  PI/180

first_names = File.readlines("./Given-Names.txt").map(&:strip)
last_names = File.readlines("./Family-Names.txt").map(&:strip)
street_names = File.readlines('./Addresses.txt').map {|x| f = x.split; f.shift; f.join(' ') }
towns = JSON.parse(File.readlines('./Towns2.txt').join).each_value {|v| v.keys_to_sym('lat', 'lng')} # contains a map of town names to lat/long map
bar_names = File.readlines('./Bar-Names.txt').map(&:strip)
company_names = File.readlines('./Companies.txt').map(&:strip).shuffle
beer_names = JSON.parse(File.readlines('./Beers.txt').join).map {|v| v.keys_to_sym}

population_size = ARGV[0] ? ARGV[0].to_i : 10000
bar_size = ARGV[1] ? [ARGV[1].to_i, bar_names.size].min : bar_names.size
town_size = ARGV[2] ? [ARGV[2].to_i, towns.keys.size].min : towns.keys.size
towns = Hash[towns.take(town_size)] if town_size < towns.size
puts "Generating a world of #{population_size} people drinking at #{bar_size} bars serving #{beer_names.size} beers in #{town_size} towns"

sample_distribution = -> dist {
  dist.sample.to_a.sample
}

randAddress = Proc.new do |town_name=nil, state=nil|
  new_town, new_state = towns.keys.sample.split(', ')
  town_name ||= new_town
  state ||= new_state

  town_loc = towns["#{town_name}, #{state}"]
  Address.new((rand * 9999).to_i, street_names.sample, town_name, state, town_loc[:lat], town_loc[:lng])
end

randAddressInTown = -> full_town_name=nil {
  return randAddress[full_town_name.split(', ')]
}

age_distribution = [(21..24), (21..24), (21..24), (21..24), (21..24), (21..24), (21..24),
                    (25..28), (25..28), (25..28),
                    (29..32), (29..32),
                    (33..40), (33..40), (33..40),
                    (41..50), (41..50), (41..50), (41..50), (41..50), (41..50), (41..50), (41..50),
                    (51..65), (51..65), (51..65),
                    (66..80), (66..80),
                    (81..100)]

company_size_distribution = [(5..50), (5..50), (5..50), (5..50), (5..50), (5..50), (5..50), (5..50), (5..50), (5..50),
                             (51..250), (51..250), (51..250), (51..250), (51..250), (51..250),
                             (250..1000), (250..1000),
                             (1001..5000)]

# make fake people, don't house them or give them jobs
people = []
population_size.times do |i|
  age = sample_distribution[age_distribution]
  people << Person.new(i, "#{first_names.sample} #{last_names.sample}", nil, nil, age)
end
puts "made people"

# make up some companies and employ people for that company in one town
companies = []
company_names.each_with_index do |company_name, id|
  break if people.empty?

  addr = randAddress[]
  c = Company.new(id, company_name, addr)

  # choose a company distribution, take that many people and relocate
  # them to a town and city, presumably that's where the company exists
  desired_company_size = sample_distribution[company_size_distribution]
  workers = people.shift(desired_company_size).each do |worker|
    address = randAddress[addr.town, addr.state]
    worker.address = address
    worker.company_id = id
  end
  c.employees = workers
  companies << c
end
puts "made companies"

# lets not care about companies with no employees
companies.delete_if {|c| c.employees.size == 0}
puts "deleted empty companies"

# if there are people without jobs, we should kill them
# people.delete_if {|p| p.company_id.nil? }
people = nil
# puts "deleted job-less people"

def haversine_distance(lat1, lon1, lat2, lon2)
  dlon_rad = (lon2 - lon1) * RAD_PER_DEG
  dlat_rad = (lat2 - lat1) * RAD_PER_DEG

  lat1_rad = lat1 * RAD_PER_DEG
  lon1_rad = lon1 * RAD_PER_DEG

  lat2_rad = lat2 * RAD_PER_DEG
  lon2_rad = lon2 * RAD_PER_DEG

  a = (Math.sin(dlat_rad/2))**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * (Math.sin(dlon_rad/2))**2
  c = 2 * Math.atan2( Math.sqrt(a), Math.sqrt(1-a))

  return 3956 * c          # delta between the two points in miles
end

# get distance between two towns. Cache the distance between two towns after one computation
town_d_cache = {}
distance_between_towns = -> town_a, town_b {
  return town_d_cache[town_a][town_b] unless town_d_cache[town_a].nil? || town_d_cache[town_a][town_b].nil?
  return town_d_cache[town_b][town_a] unless town_d_cache[town_b].nil? || town_d_cache[town_b][town_a].nil?

  d = haversine_distance(town_a[:lat], town_a[:lng], town_b[:lat], town_b[:lng])
  town_d_cache[town_a] ||= {}; town_d_cache[town_a][town_b] ||= d
  town_d_cache[town_b] ||= {}; town_d_cache[town_b][town_a] ||= d
  return d
}

nearest_towns = -> target_town, n=nil {
  distances = towns.sort_by {|town_name, town| distance_between_towns[target_town, town] }.drop(1)
  nearest = (n ? distances.take(n) : distances)
}

# generate all the beers
tf = [true, false]
beers = beer_names.map {|beer| Beer.new(beer[:name], beer[:manf], tf[rand.round], beer[:price_range].to_range)}
puts "made beers"

# make bars give each bar some portion of beers
bars = []
bar_names.take(bar_size).each_with_index do |bar_name, id|
  beer_costs = {}
  beers.shuffle.take(rand * beers.size).each do |beer|
    cost = beer.price_range.to_a.sample
    beer_costs[cost] ||= []
    beer_costs[cost] << beer
  end
  bar = Bar.new(id, bar_name, nil, beer_costs)
  bars << bar
end
bars_clone = bars.dup
puts "made bars and put beers in bars"

# put a bar in every town
towns.map {|town_name, loc| bar = bars_clone.shift(1)[0]; break if bar.nil?; bar.address = randAddressInTown[town_name];}
bars_clone.each {|bar| bar.address = randAddressInTown[towns.keys.sample]}
puts "put a bar in every town"

# show bars by town
#bars.group_by {|bar| bar.address.town_state_s}.each_pair {|town, bars| puts town; bars.each {|b| puts "\t#{b.name}"; puts b.sells }}


