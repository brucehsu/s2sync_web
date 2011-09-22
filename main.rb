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
  puts params[:content]
  content = CGI::unescape(params[:content])
  as_comment = params[:post_comment]
  content = content.split(/^\\p/)
  @agents.each { |sns, agent|
    if as_comment == 'true' then
      res = agent.post_comment(content[0].strip, session[:prev_id][sns])
    else
      res = agent.post_content(content[0].strip)
    end
    if res['error_text'] then
      stat += "<br />" unless stat == ""
      stat += "#{sns.to_s}: #{res['error_text']}"
    end

    if content.count > 1 then
      content.each_index { |index|
        res = agent.post_comment(content[index].strip) unless index == 0
        if res['error_text'] then
          stat += "<br />" unless stat == ""
          stat += "#{sns.to_s}: #{res['error_text']}"
        end
      }
    end
  }
  
  unless session[:prev_id] then
    session[:prev_id] = {}
  end

  session[:prev_id][:plurk] = @agents[:plurk].prev_id if @agents[:plurk].prev_id
  session[:prev_id][:fb] = @agents[:fb].prev_id if @agents[:fb].prev_id

  if stat == "" then
    return "Successfully posted"
  end
  return stat
end
