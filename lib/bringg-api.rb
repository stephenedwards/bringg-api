require 'net/http'
require 'json'
require 'openssl'
module BringgApi
  
  @options = {}
  class << self
    attr_accessor :options
  end
  
  class BringgAction
    def initialize
      @params = {}
      required_options = [:company_id, :access_token, :secret_key]
      required_options.each do |req_option|
        if !BringgApi.options.has_key?(req_option)
          raise BringgApi::BringgApiException::MissingOptions, "BringgApi is missing option :"+req_option.to_s
        end
      end
    end
    
    def set_params(args = {})      
      args.each do |k,v|
        @params[k] = v
      end
      return true
    end
    
    def send
      #Create request
      uri = URI(@url)
      req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
      
      #add timestamp and token to params
      @params[:timestamp] = Time.now().to_i
      @params[:access_token] = BringgApi.options[:access_token]
      @params[:company_id] = BringgApi.options[:company_id]
      tmpQuery = URI.encode_www_form(@params)
      p tmpQuery
      #sign params      
      @params[:signature] = OpenSSL::HMAC.hexdigest("sha1", BringgApi.options[:secret_key], tmpQuery).to_s
            
      req.body = @params.to_json
      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = (uri.scheme == "https")
      res = http.request(req)
      p res.code
      p res.message
      p res.body
      if res.code == "200"
        j = JSON.parse(res.body)
        if j["success"]          
          return j
        else
          raise BringgApiException::ActionError, j["message"]
        end  
      else
        raise BringgApiException::HTTPError, res.code.to_s + " " + res.message
      end      
      
    end
    
  end
    
  class CreateTask < BringgAction
    def initialize
      @url = "https://developer-api.bringg.com/partner_api/tasks"
      @id = nil
      super
    end   
    
    def send
      result = super["task"]
      @id = result["id"]
      return result
    end
    
  end
  
  class CreateTaskWithWayPoints < BringgAction
    def initialize
      @url = "https://developer-api.bringg.com/partner_api/tasks/create_with_way_points"
      @id = nil  
      @result = nil    
      super
    end
    
    def send
      @result = super["task"]
      @id = @result["id"]
      return @result
    end
    
    def add_note_to_waypoints(_note)
      if @result.nil? || @id.nil?
        return false
      end 
      
      @result["way_points"].each do |way_point|
        note = BringgApi::CreateNote.new(@id, way_point["id"])
        note.set_params(_note)
        return note.send
      end
    end
  end
  
  class CreateNote < BringgAction
    def initialize(task_id, way_point_id)
      @url = "https://developer-api.bringg.com/partner_api/tasks/"+task_id.to_s+"/way_points/"+way_point_id.to_s+"/notes"
      super()
    end
  end
  
  module BringgApiException
    class MissingOptions < Exception
    end
    class ActionError < Exception
    end
    class HTTPError < Exception
    end
  end
end