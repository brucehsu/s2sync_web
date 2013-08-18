require 'rubygems'
require 'json/pure'
require 'rest-core'

Plurk = RestCore::Builder.client do
  s = self.class
  use s::DefaultSite, 'http://www.plurk.com/APP'

  use s::Oauth1Header  ,
    'http://www.plurk.com/OAuth/request_token', 
    'http://www.plurk.com/OAuth/access_token',
    'http://www.plurk.com/OAuth/authorize'

  use s::CommonLogger  , method(:puts)

  use s::ErrorHandler , lambda { |env|
    Plurk::Error.new(env["RESPONSE_BODY"])
  }
  use s::JsonResponse, true

  use s::Cache       , {}, 3600
end

class Plurk::Error < RuntimeError
  attr_reader :error

  def initialize (error)
    @error = error
    super(error["error_text"])
  end
end

module Plurk::Client
  def add_plurk content, qualifier='says'
    post('/Timeline/plurkAdd', {"content"=>content, "qualifier" => qualifier})
  end

  def add_response plurk_id, content, qualifier='says'
    post('/Responses/responseAdd', {'plurk_id' => plurk_id,
           'content' => content, 'qualifier' => qualifier})
  end
end

Plurk.send(:include, RestCore::ClientOauth1)
Plurk.send(:include, Plurk::Client)
