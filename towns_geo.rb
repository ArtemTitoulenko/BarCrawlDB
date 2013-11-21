require 'open-uri'
require 'json'
require 'pry'

town_names = File.open('./Towns.txt', 'r').readlines.map(&:strip)

towns = {}
town_names.each do |town|
  open("http://maps.googleapis.com/maps/api/geocode/json?sensor=false&address=#{town.gsub(' ', '+')}") { |res|
    res = JSON.parse(res.lines.to_a.join)
    sleep 0.5
    towns[town] = res["results"][0]["geometry"]["location"]
  }
end

File.open('./Towns2.txt', 'w+').puts(towns.to_json)

