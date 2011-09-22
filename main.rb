require 'oauth_const'
require 'fb_agent'
require 'plurk_agent'

require 'rubygems'
require 'sinatra'
require 'haml'
require 'sass'
require 'oauth'
require 'net/http'
require 'uri'

enable :sessions


get '/' do
  session[:plurk] = {}
  session[:fb] = {}
  @auth_url = {}

  @auth_url[:fb] = "https://www.facebook.com/dialog/oauth?client_id=#{FB_APP_KEY}&redirect_uri=" +
    CGI::escape("http://s2sync.brucehsu.org/fb_callback") + "&scope=publish_stream,read_stream,user_about_me,offline_access"

  @consumer= OAuth::Consumer.new(PLURK_APP_KEY, PLURK_APP_SECRET, {
        :site => 'http://www.plurk.com',
        :scheme => :header,
        :http_method => :post,
        :request_token_path => '/OAuth/request_token',
        :access_token_path => '/OAuth/access_token',
        :authorize_path => '/OAuth/authorize'
                                 })
  @request_token = @consumer.get_request_token(:oauth_callback => "http://s2sync.brucehsu.org/plurk_callback")
  @auth_url[:plurk] = @request_token.authorize_url

  session[:plurk][:request_token] = @request_token

  haml :index
end

get '/stylesheet.css' do
  scss :stylesheet
end

get '/fb_callback' do
  code = params[:code]
  uri = URI.parse("https://graph.facebook.com")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  res = http.get("/oauth/access_token?" +
                  "client_id=#{FB_APP_KEY}&redirect_uri=" +
                  CGI::escape("http://s2sync.brucehsu.org/fb_callback") +
                  "&client_secret=#{FB_APP_SECRET}&code=#{code}" ,nil)
  @access_token = res.body.split('=',2)[1]
  session[:fb][:access_token] = @access_token
end


get '/plurk_callback' do
  @request_token = session[:plurk][:request_token]
  @access_token = @request_token.get_access_token :oauth_verifier => params[:oauth_verifier]
  session[:plurk][:access_token] = @access_token

  @token = @access_token.token
  @secret = @access_token.secret

  haml :plurk_callback
end

