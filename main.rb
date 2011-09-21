require 'oauth_const'
require 'fb_agent'
require 'plurk_agent'

require 'rubygems'
require 'sinatra'
require 'haml'
require 'sass'

set :agents, {}

get '/' do
  @auth_url = {}

  options.agents[request.ip] = {} unless options.agents.has_key? request.ip
  @agents = options.agents[request.ip]

  @agents[:fb] = FBAgent.new unless @agents.has_key? :fb
  @agents[:plurk] = PlurkAgent.new unless @agents.has_key? :plurk

  @agents.each { |key, agent|
    @auth_url[key] = agent.get_authorize_url(request.host,request.port)
  }
  haml :index
end

get '/stylesheet.css' do
  scss :stylesheet
end

get '/fb_callback' do
  if not params.has_key? "code" then
    redirect to('/')
  end

  code = params[:code]
end

get '/plurk_callback' do
  plurk = options.agents[request.ip][:plurk]
  access_token = plurk.get_access_token(params[:oauth_verifier])
  @token = access_token[:token]
  @secret = access_token[:secret]
  haml :plurk_callback
end
