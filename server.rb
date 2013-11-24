require 'sinatra'
require 'haml'
require 'json'

require 'mysql2'

client = Mysql2::Client.new(:host => "localhost", :username => "root")
client.query('use barcrawldb;')

q = -> query { return client.query(query).to_a }

sizes = {}
['drinker', 'bar', 'beer', 'buys'].map do |x|
  sizes[x] = (q["select count(*) from #{x};"].first)["count(*)"]
end

bars_per_age_per_day = q["select buys.day, drinker.age, avg(buys.bar_number) as num_bars from drinker, buys
where drinker.id = buys.drinker_id
group by buys.day, drinker.age"].group_by {|x| x["day"]}

top_selling_beer = q["Select beer.name, COUNT(*) as count
From buys, beer
Where beer.id = buys.beer_id AND buys.quantity
Group By beer.name
Order By 2 Desc
limit 5
"]

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

