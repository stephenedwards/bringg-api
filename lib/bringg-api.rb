require 'net/http'
require 'json'
module BringgApi
  
  class Options
    @action_urls = {}    
    def self.set_action_url(args = {})      
      if args.class != Hash
        raise BringgApiException::IncorrectParams, "Expecting Hash as parameter: :action => 'url'"
        return
      end
      args.each do |k, v|
        @action_urls[k] = v
      end
      
      
      return true
    end
    
    def self.get_action_url(_action)
      if @action_urls.has_key?(_action)
        @action_urls[_action]
      else
        nil  
      end
    end
  end  
     
  class CreateTask
    def initialize
      action_url = Options.get_action_url(:create_task)
      if action_url.nil?
        raise BringgApiException::ActionNotDefined, "Action URL for 'create_task' not set"
        return
      end
      @url = action_url
      @params = {}
    end
    
    def set_params(args = {})
      args.each do |k,v|
        @params[k] = v
      end
      return true
    end
    
    def send
      uri = URI(@url)
      req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
      req.body = @params.to_json
      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = (uri.scheme == "https")
      res = http.request(req)
      j = JSON.parse(res.body)
      if j["success"]
        return j ["task"]
      else
        raise BringgApiException::ErrorCreatingTask, j["message"]
      end
    end
  end
  
  
  module BringgApiException
    class ActionNotDefined < Exception
    end
    class IncorrectParams < Exception 
    end
    class MissingParams < Exception 
    end
    class ErrorCreatingTask < Exception
      
    end
  end
end