require 'json'
require 'pry'
require 'mysql2'

require './util'
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
                    (25..27), (25..27), (25..27), (25..27),
                    (28..29), (28..29), (28..29),
                    (30..32), (30..32),
                    (33..40), (33..40), (33..40),
                    (41..50), (41..50), (41..50), (41..50), (41..50), (41..50), (41..50), (41..50),
                    (51..55), (51..55), (51..55), (51..55), (51..55),
                    (56..60), (56..60), (56..60),
                    (61..65), (61..65),
                    (66..70), (66..70),
                    (71..100)]

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

nearest_towns = -> host_town, n=nil {
  distances = towns.sort_by {|town_name, town| distance_between_towns[host_town, town] }.drop(1)
  n ? distances.take(n) : distances
}

# generate all the beers
tf = [true, false]
beers = []
beer_names.each_with_index {|beer, id| beers << Beer.new(id, beer[:name], beer[:manf], tf[irand()], beer[:price_range].to_range)}
puts "made beers"

# make bars give each bar some portion of beers
bars = []
bar_names.take(bar_size).each_with_index do |bar_name, id|
  beer_costs = {}
  beers.shuffle.take(irand(beers.size-2)+1).each do |beer|
    cost = beer.price_range.to_a.sample
    beer_costs[cost] ||= []
    beer_costs[cost] << beer
  end
  bar = Bar.new(id, bar_name, nil, beer_costs)
  bars << bar
end
bars_clone = bars.dup
puts "made bars and put beers in bars"

nearest_bars = -> host_town, n=nil {
  distances = bars.sort_by {|bar| distance_between_towns[host_town, bar.address]}.drop(1)
  n ? distances.take(n) : distances
}

# put a bar in every town
towns.map {|town_name, loc| bar = bars_clone.shift(1)[0]; break if bar.nil?; bar.address = randAddressInTown[town_name];}
bars_clone.each {|bar| bar.address = randAddressInTown[towns.keys.sample]}
puts "put a bar in every town"

# show bars by town
#bars.group_by {|bar| bar.address.town_state_s}.each_pair {|town, bars| puts town; bars.each {|b| puts "\t#{b.name}"; puts b.sells }}

#######################
#                     #
# START THE BAR CRAWL #
#                     #
#######################

puts "getting everyone WICKED hammered"

buys = []
weekday_drinking_prob_young = [0.4, 0.05, 0.05, 0.1, 0.15, 0.5, 0.8]
weekday_drinking_prob_old = [0.02, 0.01, 0.01, 0.01, 0.01, 0.3, 0.4]
weekday_drinking = [weekday_drinking_prob_young, weekday_drinking_prob_old]

days_of_drinking = 31 * 6 # 6 months

is_old = -> person { return person.age > 30 ? 1 : 0 }

buy_some_drinks = -> person, bar, day, bar_of_the_day, week_num {
  # young people drink less beer and it's cheaper beer
  old = is_old[person]

  beer_prices = bar.sells.keys.sort
  cheap = beer_prices.shift(beer_prices.size/2)
  expensive = beer_prices
  categories = [cheap, expensive]

  # old == 0 => 2 beers at most, old == 1 => 4 beers at most
  # old == 0 => cheap list, old == 1 => expensive list
  # try to grab a beer from that person's preferred category
  # if it's not there, grab one from the other one
  category = [cheap, expensive][old]
  category = [cheap, expensive][(old == 0 ? 1 : 0)] if category.empty?
  beer = bar.sells[category.sample].sample
  buys << Buys.new(bar.id, person.id, beer.id, irand([2,4][old])+1, day, bar_of_the_day, week_num)
}

# people[], bars[], day, bar_of_the_day int
bar_crawl = -> people, bars, day, week_num {
  bars.each_with_index do |bar, bar_of_the_day|
    people.each do |person|
      # young people drink less beer and it's cheaper beer
      old = is_old[person]

      # if they probably aren't drinking today, don't buy any drinks
      next if weekday_drinking[old][day] > rand

      buy_some_drinks[person, bar, day, bar_of_the_day, week_num]
    end
  end
}

# pick some people from every company and make them go on a bar crawl together
companies.each do |company|
  # take all the workers, some percentage >= 50 of the company's workers and deem them drinkers
  # and sort them by age, so drinking buddies are of similar age
  company_workers = company.employees.dup

  drinking_workers = company_workers.shift(company_workers.size/2 + irand(company_workers.size * 0.5)).sort_by! {|a| a.age}

  # create workers who go drinking alone, to add noise, but not enough to ruin everything
  noise_drinkers = company_workers.shift(irand(company_workers.size * 0.10))

  # make groups of drinking buddies, they always go to the same bars together
  drinking_groups = []
  while not drinking_workers.empty? do
    # drinking buddies, groups of employees who drink together, are no larger than 11 people
    drinking_groups << drinking_workers.shift(2 + irand(9))
  end

  nearby_bars = nearest_bars[company.address]
  drinking_groups.each do |group|
    age_average = group.reduce(0) {|memo, person| memo + person.age} / group.size

    the_regular = nearby_bars.drop(irand(4)).take(age_average > 30 ? 2 : 5) # the bar crawl that the group does the most often

    # simulate their drinking lives
    days_of_drinking.times do |day|
      day_of_the_week = day % 7

      # old people visit at most 2 bars, young visit 4
      num_bars_to_visit = (age_average > 30 ? irand(2) : irand(4))

      # do "the regular" 75% of the time
      if rand > 0.25
        bar_crawl[group, the_regular, day_of_the_week, day/7]
      else
        # skip at most 4 of the nearby bars, and try to visit the others
        bar_crawl[group, nearby_bars.drop(irand(4)).take(num_bars_to_visit), day_of_the_week, day/7]
      end
    end
  end
end

puts "wow! your population averages #{ 1.0 * buys.size / population_size / days_of_drinking} beers a day"

# lets start populating a database with BIG DATA
# lol security

config = {host: 'localhost', username: 'root'} unless ENV['BARCRAWLDB_ENV'] == 'prod'
config = {host: 'localhost', username: 'csuser', password: 'csb0684d'} if ENV['BARCRAWLDB_ENV'] == 'prod'

client = Mysql2::Client.new(config)
init_database(client)
init_tables(client)

# insert companies and their workers
companies.each do |company|
  insert_company(client, company)
  insert_drinkers(client, company.employees)
end

# insert beers
beers.each do |beer|
  insert_beer(client, beer)
end

# insert bars and the beers they sell
bars.each do |bar|
  insert_bar(client, bar)

  bar.sells.each_pair do |price, beers|
    beers.each do |beer|
      insert_beer_sale(client, bar, beer, price)
    end
  end
end

# insert sales
buys.each_slice(200).each do |buys|
  insert_purchases(client, buys)
end

puts "DONE!"
