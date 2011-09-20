require 'rubygems'
require 'sinatra'

get '/' do
  haml :index
end

get 'fb_callback' do

end
