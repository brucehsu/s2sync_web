require 'oauth_const'
require 'fb_agent'
require 'plurk_agent'

require 'rubygems'
require 'sinatra'
require 'haml'
require 'sass'

enable :sessions

before do
  @agents = {}

  if session[:plurk_attr] then
    @agents[:plurk] = PlurkAgent.new(session[:plurk_attr])
  else
    @agents[:plurk] = PlurkAgent.new
  end

  if session[:fb_attr] then
    @agents[:fb] = FBAgent.new(:access_token => session[:fb_attr])
  else
    @agents[:fb] = FBAgent.new
  end
end

after do
  session[:plurk_attr] = @agents[:plurk].attributes
#  session[:fb_attr] = @agents[:fb].attributes
end

get '/' do
  @auth_url = {}
  @agents.each { |sns, agent|
    @auth_url[sns] = agent.get_authorize_url request.host,request.port unless session["#{sns.to_s}_attr".to_sym]
  }

  haml :index
end

get '/stylesheet.css' do
  scss :stylesheet
end

get '/fb_callback' do
  code = params[:code]

  fb = @agents[:fb]
  session[:fb_attr] = fb.get_access_token code
end


get '/plurk_callback' do
  plurk = @agents[:plurk]
  access_token = plurk.get_access_token(params[:oauth_verifier])
  @token = access_token[:token]
  @secret = access_token[:secret]
  haml :plurk_callback
end

post '/post' do
  stat = ""
  @agents.each { |sns, agent|
    res = agent.post_content(params[:content])
    if res['error_text'] then
      stat += "<br />" unless stat == ""
      stat += "#{sns.to_s}: #{res['error_text']}"
    end
  }
  if stat == "" then
    return "Successfully posted"
  end
  return stat
end
