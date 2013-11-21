require 'json'
require 'pry'

RAD_PER_DEG = 0.017453293  #  PI/180

class Hash
  def sample(n=1)
    self.keys.shuffle.take(n)
  end
end

Address = Struct.new(:number, :street, :town, :state, :lat, :lng) do
  def to_loc
    {lat: self.lat, lng: self.lng}
  end

  def town_state_s
    "#{self.town}, #{self.state}"
  end

  def to_s
    "%i %s, %s {%f, %f}" % [self.number, self.street, self.town_state_s(), self.lat, self.lng]
  end
end

Bar = Struct.new(:id, :name, :address) do
  def to_s
    "#{self.id}: #{self.name} (#{self.address.to_s})"
  end
end

Person = Struct.new(:id, :name, :address, :company_id, :age)
Company = Struct.new(:id, :name, :address, :employees)

first_names = File.open("./Given-Names.txt", "r").readlines.map(&:strip)
last_names = File.open("./Family-Names.txt", "r").readlines.map(&:strip)
street_names = File.open('./Addresses.txt', "r").readlines.map {|x| f = x.split; f.shift; f.join(' ') }
towns = JSON.parse(File.open('./Towns2.txt', "r").readlines.join).each_pair { |k,t|
  t[:lat] = t['lat']; t[:lng] = t['lng'];
  t.delete 'lat'; t.delete 'lng';} # contains a map of town names to lat/long map
bar_names = File.open('./Bar-Names.txt', "r").readlines.map(&:strip)
company_names = File.open('./Companies.txt', "r").readlines.map(&:strip).shuffle

population_size = ARGV[0] ? ARGV[0].to_i : 10000
bar_size = ARGV[1] ? [ARGV[1].to_i, bar_names.size].min : bar_names.size
town_size = ARGV[2] ? [ARGV[2].to_i, towns.keys.size].min : towns.keys.size
puts "Generating a world of #{population_size} people drinking at #{bar_size} bars in #{town_size} towns"

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
people_clone = people.dup

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

# lets not care about companies with no employees
companies.delete_if {|c| c.employees.size == 0}

# if there are people without jobs, we should kill them
people.delete_if {|p| p.company_id.nil? }

def haversine_distance(lat1, lon1, lat2, lon2)
  dlon = lon2 - lon1
  dlat = lat2 - lat1

  dlon_rad = dlon * RAD_PER_DEG
  dlat_rad = dlat * RAD_PER_DEG

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

bars = []
bar_names.take(bar_size).each_with_index do |bar_name, id|
  bars << Bar.new(id, bar_name, nil)
end
bars_clone = bars.dup

locs_with_companies = companies.map {|c| c.address.to_loc }
locs_with_companies_clone = locs_with_companies.dup

# put a bar in every town
towns.map {|town_name, loc| bar = bars_clone.shift(1)[0]; break if bar.nil?; bar.address = randAddressInTown[town_name];}
bars_clone.each {|bar| bar.address = randAddressInTown[towns.keys.sample]}

bars.group_by {|bar| bar.address.town_state_s}.each_pair {|town, bars| puts town; bars.each {|b| puts "\t#{b.name}"}}
