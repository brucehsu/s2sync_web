require 'rubygems'
require 'sinatra'
require 'haml'
require 'sass'

get '/' do
  haml :index
end

get '/stylesheet.css' do
  scss :stylesheet
end

get '/fb_callback' do
  code = params.keys.first
end

