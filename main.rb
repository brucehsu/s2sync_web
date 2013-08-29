require "rubygems"
require "bundler/setup"

$LOAD_PATH << '.'
require 'oauth_const'
require 'fb_agent'
require 'plurk_agent'
require 'twitter_agent'

require 'sinatra'
require 'slim'
require 'sass'
require 'coffee_script'
require 'nokogiri'
require 'open-uri'

configure do
   enable :sessions
   set :protection, :except => [:remote_token, :http_origin]
end

before do
  @agents = {}
  @auth_stat = {}
  @agents[:plurk] = PlurkAgent.new(session[:plurk_attr]||{})
  @agents[:facebook] = FBAgent.new(:access_token => session[:facebook_attr])
  @agents[:twitter] = TwitterAgent.new(:data=>session[:twitter_attr])
end

after do
  session[:plurk_attr] = @agents[:plurk].attributes
  session[:twitter_attr] = @agents[:twitter].data
  #  session[:facebook_attr] = @agents[:facebook].attributes
end

def check_agents_authorization
  @agents.each do |sns, agent|
    @auth_stat[sns] = agent.has_authorized?
  end
  @agents[:plurk] = PlurkAgent.new unless @auth_stat[:plurk]
  @agents[:facebook] = FBAgent.new unless @auth_stat[:facebook]
  @agents[:twitter] = TwitterAgent.new unless @auth_stat[:twitter]
end

get '/' do
  check_agents_authorization

  @auth_url = {}
  @agents.each { |sns, agent|
	 @auth_url[sns] = agent.get_authorize_url request.host,request.port unless @auth_stat[sns]
  }

  #Work-around when PlurkAgent generate url without request token, the cause is token being used twice returns HTTP 401
  unless @agents[:plurk].has_authorized? then
	unless @auth_url[:plurk].include? "http://www.plurk.com/OAuth/authorize?oauth_token="
      @agents[:plurk] = PlurkAgent.new
      @auth_url[:plurk] = @agents[:plurk].get_authorize_url
    end
  end

  slim :index
end

get '/stylesheet.css' do
  scss :stylesheet
end

get '/s2sync.js' do
  coffee :s2sync
end

get '/fb_callback' do
  code = params[:code]

  fb = @agents[:facebook]
  session[:facebook_attr] = fb.get_access_token code
  redirect to('/')
end


get '/plurk_callback' do
  plurk = @agents[:plurk]
  access_token = plurk.get_access_token(params[:oauth_verifier])
  @token = access_token[:token]
  @secret = access_token[:secret]
  redirect to('/')
  haml :plurk_callback
end

get '/tw_callback' do
  twitter = @agents[:twitter]
  access_token = twitter.get_access_token(params[:oauth_verifier])
  redirect to('/')
end

post '/post' do
  stat = ""
  unless session[:prev_id] then
	 session[:prev_id] = {}
  end
  content = params[:content]
  as_comment = params[:post_comment]
  content = content.split(/^\\p/)
  @agents.each { |sns, agent|
  	if as_comment == 'true' then
  	  res = agent.post_comment(content[0].strip, session[:prev_id][sns])
  	else
  	  res = agent.post_content(content[0].strip)
  	  session[:prev_id][sns] = agent.prev_id
  	end
  	if res['error_text'] then
  	  stat += "<br />" unless stat == ""
  	  stat += "#{sns.to_s}: #{res['error_text']}"
  	end

  	if content.count > 1 then
  	  content.each_index { |index|
  		res = agent.post_comment(content[index].strip) unless index == 0
  		error_msg = ''
  		if res['error_text']then
  		  error_msg = "#{sns.to_s}: #{res['error_text']}"
  		elsif res['error'] 
  		  error_msg = "#{sns.to_s}: #{res['error']['type']}: #{res['error']['message']}"
  		end
  		stat += "<br />" if not stat.empty? and not error_msg.empty?
  		stat += error_msg unless error_msg.empty?
  	  }
  	end
  }

  if stat == "" then
	 return '<li class="success alert">' + "Successfully posted" + '</div>'
  end
  return '<li class="danger alert">' + stat + '</div>'
end

get '/get_page_title/:url' do |url|
    url = URI::decode_www_form_component url
    url = 'http://' + url unless url.match(/https?:\/\//i)
    head = ''
    open(url) do |f|
        f.each_line do |l|
            head += l
            break if l.match(/<\/head>/i)
        end
    end
    doc = Nokogiri::XML(head)
    doc.css("title").text
end
