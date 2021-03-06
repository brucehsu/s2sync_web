require 'rubygems'
require 'oauth_const'
require 'plurk'

class PlurkAgent
  attr_reader :prev_id

  def initialize(opt={})
    if opt=={} then 
      opt[:consumer_key] =  PLURK_APP_KEY
      opt[:consumer_secret] = PLURK_APP_SECRET 
    end
    @plurk = Plurk.new(opt)
  end

  def get_authorize_url(host, port)
    return @plurk.authorize_url!
  end

  def get_access_token(verifier_or_token=nil,secret=nil)
    if not verifier_or_token == nil then
      if secret == nil then
        @plurk.authorize!(:oauth_verifier=>verifier_or_token)
      else
        @plurk.oauth_token = verifier_or_token
        @plurk.oauth_token_secret = secret
      end
    end
    return {:token => @plurk.oauth_token, :secret => @plurk.oauth_token_secret}
  end

  def has_authorized?
    res = @plurk.post("/checkToken")
    return res['error_text'] ? false : true
  end

  def post_content(content,qualifier='says')
    begin
      return_content = @plurk.add_plurk(content,qualifier)
      @prev_id = return_content['plurk_id']
      return_content
    rescue RuntimeError  => err
      puts err
    end
  end

  def post_comment(content,id=@prev_id,qualifier='says')
    @plurk.add_response(id,content,qualifier)
  end

  def attributes
    return @plurk.lighten.attributes
  end
end
