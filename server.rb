require 'sinatra'
require 'haml'

configure do
  set :bind, '0.0.0.0'
  set :static, true
  set :public_folder, 'public'
end


get '/' do
  haml :index
end

