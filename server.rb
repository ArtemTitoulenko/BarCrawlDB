require 'sinatra'
require 'haml'
require 'json'

require 'mysql2'

config = {host: 'localhost', username: 'root'} unless ENV['BARCRAWLDB_ENV'] == 'prod'
config = {host: 'localhost', username: 'csuser', password: 'csb0684d'} if ENV['BARCRAWLDB_ENV'] == 'prod'

client = Mysql2::Client.new(config)
client.query('use barcrawldb;')

q = -> query { return client.query(query).to_a }

sizes = {}
['drinker', 'bar', 'beer', 'buys'].map do |x|
  sizes[x] = (q["select count(*) from #{x};"].first)["count(*)"]
end

puts " got sizes"

bars_per_age_per_day = q["select buys.day, drinker.age, avg(buys.bar_number) as num_bars from drinker, buys
where drinker.id = buys.drinker_id
group by buys.day, drinker.age"].group_by {|x| x["day"]}

puts "got bars per age per day"

top_selling_beer = q["Select beer.name, COUNT(*) as count
From buys, beer
Where beer.id = buys.beer_id AND buys.quantity
Group By beer.name
Order By 2 Desc
limit 5
"]

puts "got top selling beer"

configure do
  set :bind, '0.0.0.0'
  set :static, true
  set :public_folder, 'public'
end


get '/' do
  haml :index, locals: {
    sizes: sizes,
    drinker_age_dist: q["select age, count(*) as count from drinker group by age;"].map{|x| x['count'] }.to_json,
    bars_per_age_per_day: bars_per_age_per_day.to_json,
    top_selling_beer: top_selling_beer
  }
end

