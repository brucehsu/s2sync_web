require 'rubygems'
require 'json/pure'
require 'rest-core/client/facebook'

class FBAgent
  attr_reader :prev_id

  def initialize(opt={})
    if opt=={} then 
      opt[:app_id] = FB_APP_KEY
      opt[:secret] = FB_APP_SECRET
    end
    @facebook = RestCore::Facebook.new(opt)
  end

  def get_authorize_url(host,port)
    return @facebook.authorize_url(:scope =>  'publish_stream,read_stream,user_about_me,offline_access',
                                   :redirect_uri => "http://s2sync.brucehsu.org/fb_callback")
  end

  def get_access_token(code, token=nil)
    if token == nil
      @facebook.authorize!(:redirect_uri => 'http://s2sync.brucehsu.org/fb_callback',
                           :code => code)
    else
      @facebook.access_token = token
    end
    get_user_id
    return @facebook.access_token
  end

  def post_content(content)
	content = content.strip
    content = parse_url(content)
    @prev_id = @facebook.post("#{@user_id}/feed",{'message' => content[:content],
                   'link' => content[:url]},
                   nil)
    @prev_id = @prev_id['id']
  end

  def post_comment(content,id=@prev_id)
    @facebook.post("#{id}/comments",{'message' => content})
  end

  def get_user_id(token = nil)
    @user_id = @facebook.get('me')['id']
  end

  def parse_url(content)
    link_and_content = {:url => ''}
    if content.split(/ /)[0] =~ /(http|https):\/\/(\w|\W)+/ then
      link_and_content[:url] = content.split(/ /)[0]
	  content = content.split(/ /, 2)[1]
      if content != nil and content.match(/(\([\w|\W|\p{L}]+\))/u) != nil then
        if content.split(/(\([\w|\W|\p{L}]+\) +)/u).count > 1  then
			content = content.split(/(\([\w|\W|\p{L}]+\) +)/u)[2]
		else
			content.sub!(/(\([\w|\W|\p{L}]+\))/u,'')
		end
      end
    end
    link_and_content[:content] = content
    return link_and_content
  end

  def attributes
    return @facebook.lighten.attributes
  end
end
