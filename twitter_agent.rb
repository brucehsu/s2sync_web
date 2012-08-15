require 'rubygems'
require 'json/pure'
require 'rest-more'

RC::Twitter::Error.send :remove_method, :code

class TwitterAgent
  def initialize(opt={})
    opt[:consumer_key] = TWITTER_APP_KEY
    opt[:consumer_secret] = TWITTER_APP_SECRET
    @twitter = RC::Twitter.new(opt)
  end

  def get_authorize_url(host, port)
    return @twitter.authorize_url!
  end

  def get_access_token(verifier_or_token=nil,secret=nil)
    if not verifier_or_token == nil then
      if secret == nil then
        @twitter.authorize!(:oauth_verifier=>verifier_or_token)
      else
        @twitter.oauth_token = verifier_or_token
        @twitter.oauth_token_secret = secret
      end
    end
    return {:token => @twitter.oauth_token, :secret => @twitter.oauth_token_secret}
  end

  def get_user_id
    @twitter.data['user_id']
  end

  def get_user_name
    @twitter.data['screen_name']
  end

  def has_authorized?
    begin
      res = @twitter.get('1/statuses/home_timeline.json',{}, {:count=>5})
      return true
    rescue
      return false
    end
  end

  def post_content(content)
    content.strip!
    return_content = @twitter.tweet(content)
    @prev_id = return_content['id_str']
    return_content
  end

  def post_comment(content)
    content.strip!
    content = "@#{get_user_name} " + content
    return_content = @twitter.tweet(content,nil,{:in_reply_to_status_id=>@prev_id},{},{})
    @prev_id = return_content['id_str']
    return_content
  end

  def attributes
    return @twitter.lighten.attributes
  end

  def data
    return @twitter.data
  end

end
