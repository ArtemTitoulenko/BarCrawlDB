require 'json'
require 'pry'

Address = Struct.new(:number, :street, :town, :state)
Bar = Struct.new(:id, :name, :address)
Person = Struct.new(:id, :name, :address, :company_id, :age)
Company = Struct.new(:id, :name, :address, :num_employees)

population_size = (ARGV[0].to_i || 10000)

first_names = File.open("./Given-Names.txt", "r").readlines.map(&:strip)
last_names = File.open("./Family-Names.txt", "r").readlines.map(&:strip)
street_names = File.open('./Addresses.txt', "r").readlines.map {|x| f = x.split; f.shift; f.join(' ') }
town_names = JSON.parse(File.open('./Towns2.txt', "r").readlines.join) # contains a map of town names to lat/long map
bar_names = File.open('./Bar-Names.txt', "r").readlines.map(&:strip)
company_names = File.open('./Companies.txt', "r").readlines.map(&:strip).shuffle

binding.pry

sample_distribution = -> dist {
  dist.sample.to_a.sample
}

randAddress = -> town=nil, state=nil {
  new_town, new_state = town_names.keys.sample.split(', ')
  return Address.new((rand * 9999).to_i, street_names.sample, town || new_town, state || new_state)
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
  puts "#{c.name}, #{workers.size}"
  companies << c
end


