require 'net/http'
require 'json'
require 'openssl'
module BringgApi
  
  @options = {}
  class << self
    attr_accessor :options
  end
  
  class BringgActionPost    
    attr_accessor :url
    
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
      req = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json')
      
      #add timestamp and token to params
      @params[:timestamp] = Time.now().to_i
      @params[:access_token] = BringgApi.options[:access_token]
      @params[:company_id] = BringgApi.options[:company_id]
      tmpQuery = URI.encode_www_form(@params)
      
      #sign params      
      @params[:signature] = OpenSSL::HMAC.hexdigest("sha1", BringgApi.options[:secret_key], tmpQuery).to_s
            
      req.body = @params.to_json
      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = (uri.scheme == "https")
      res = http.request(req)      
      if res.code == "200"
        j = JSON.parse(res.body)        
        if (j.has_key?("success") && j["success"]) || !j.has_key?("success") 
          return j
        else
          raise BringgApiException::ActionError, j["message"]
        end  
      else
        raise BringgApiException::HTTPError, res.code.to_s + " " + res.message
      end
    end
  end
  
  class BringgActionGet < BringgActionPost   
    attr_accessor :url     
    def send
      #Create request      
      uri = URI(@url)
      
      #add timestamp and token to params
      @params[:timestamp] = Time.now().to_i
      @params[:access_token] = BringgApi.options[:access_token]
      @params[:company_id] = BringgApi.options[:company_id]
      tmpQuery = URI.encode_www_form(@params)
      
      #sign params      
      @params[:signature] = OpenSSL::HMAC.hexdigest("sha1", BringgApi.options[:secret_key], tmpQuery).to_s            
      uri.query = URI.encode_www_form(@params)
      
      Net::HTTP.start(uri.host, uri.port, :use_ssl => (uri.scheme == 'https')) do |http|
        request = Net::HTTP::Get.new uri.request_uri        
        res = http.request(request)
        if res.code == "200"
          j = JSON.parse(res.body)          
          return j           
        else
          if res.code == "404"
            raise BringgApiException::HTTPNotFound, res.code.to_s + " " + res.message 
          else
            raise BringgApiException::HTTPError, res.code.to_s + " " + res.message
          end
        end
      end 
    end
  end
  
  class BringgActionPatch < BringgActionPost   
    attr_accessor :url     
    def send
      #Create request
      uri = URI(@url)
      req = Net::HTTP::Patch.new(uri.request_uri, 'Content-Type' => 'application/json')
      
      #add timestamp and token to params
      @params[:timestamp] = Time.now().to_i
      @params[:access_token] = BringgApi.options[:access_token]
      @params[:company_id] = BringgApi.options[:company_id]
      tmpQuery = URI.encode_www_form(@params)
      
      #sign params      
      @params[:signature] = OpenSSL::HMAC.hexdigest("sha1", BringgApi.options[:secret_key], tmpQuery).to_s
            
      req.body = @params.to_json
      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = (uri.scheme == "https")
      res = http.request(req)
      puts res.body
      if res.code == "200"
        j = JSON.parse(res.body)
        if (j.has_key?("success") && j["success"]) || !j.has_key?("success")        
          return j
        else
          raise BringgApiException::ActionError, j["message"]
        end  
      else
        raise BringgApiException::HTTPError, res.code.to_s + " " + res.message
      end
    end
  end
  
  class BringgActionDelete < BringgActionPost   
    attr_accessor :url     
    def send
      #Create request
      uri = URI(@url)
      req = Net::HTTP::Delete.new(uri.request_uri, 'Content-Type' => 'application/json')
      
      #add timestamp and token to params
      @params[:timestamp] = Time.now().to_i
      @params[:access_token] = BringgApi.options[:access_token]
      @params[:company_id] = BringgApi.options[:company_id]
      tmpQuery = URI.encode_www_form(@params)
      
      #sign params      
      @params[:signature] = OpenSSL::HMAC.hexdigest("sha1", BringgApi.options[:secret_key], tmpQuery).to_s
            
      req.body = @params.to_json
      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = (uri.scheme == "https")
      res = http.request(req)
      
      if res.code == "200"
        j = JSON.parse(res.body)
        if (j.has_key?("success") && j["success"]) || !j.has_key?("success")        
          return j
        else
          raise BringgApiException::ActionError, j["message"]
        end  
      else
        raise BringgApiException::HTTPError, res.code.to_s + " " + res.message
      end
    end
  end
  
  module Task
    class Create < BringgActionPost
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
    
    class CreateWithWayPoints < BringgActionPost
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
          note = BringgApi::Note::Create.new(@id, way_point["id"])
          note.set_params(_note)
          note.send
        end
      end
    end
  end
    
  module Note
    class Create < BringgActionPost
      def initialize(task_id, way_point_id)
        @url = "https://developer-api.bringg.com/partner_api/tasks/"+task_id.to_s+"/way_points/"+way_point_id.to_s+"/notes"
        super()
      end
    end  
  end
  
  module Customer
    class Create < BringgActionPost
      def initialize
        @url = "https://developer-api.bringg.com/partner_api/customers" 
        super
      end
      
      def send
        super["customer"]
      end
    end
    
    class Update < BringgActionPatch
      def initialize(_customer_id)
        @url = "https://developer-api.bringg.com/partner_api/customers/"+_customer_id.to_s
        super()
      end
      
      def send
        super["customer"]
      end
    end
    
    def self.get(_customer_id)      
      action = BringgActionGet.new
      action.url = "https://developer-api.bringg.com/partner_api/customers/"+_customer_id.to_s 
      res = action.send
      res["customer"]
    end
    
    def self.get_by_external_id(_external_id)
      action = BringgActionGet.new
      action.url = "https://developer-api.bringg.com/partner_api/customers/external_id/"+_external_id.to_s 
      res = action.send
      res
    end
    
    def self.fetch_by_external_id(_external_id)
      begin        
        customer = get_by_external_id(_external_id)        
        if block_given?          
          action = Customer::Update.new(customer["id"])
          params = yield          
          action.set_params(params)
          action.send
        end
      rescue BringgApiException::HTTPNotFound => e        
        if block_given?          
          action = Customer::Create.new
          params = yield
          params[:external_id] = _external_id
          action.set_params(params)
          action.send
        else
          raise BringgApiException::HTTPNotFound
        end
      end
    end
  end  
  
  module Team
    class Create < BringgActionPost
      def initialize
        @url = "https://developer-api.bringg.com/partner_api/teams"
        super
      end      
    end
    
    class Update < BringgActionPatch
      def initialize(_id)
        @url = "https://developer-api.bringg.com/partner_api/teams/"+_id.to_s
        super()
      end
    end
    
    def self.delete(_id)
      action = BringgActionDelete.new
      action.url = "https://developer-api.bringg.com/partner_api/teams/"+_id.to_s
      res = action.send
      res["success"]
    end
    
    def self.all
      action = BringgActionGet.new
      action.url = "https://developer-api.bringg.com/partner_api/teams" 
      res = action.send
      res
    end
    
    def self.get(_team_id)
      teams = self.all
      teams.find {|t| t["id"] == _team_id}
    end
    
    def self.get_by_external_id(_external_id)
      teams = self.all
      teams.find {|t| t["external_id"] == _external_id}
    end
  end
    
  module BringgApiException
    class MissingOptions < Exception
    end
    class ActionError < Exception
    end
    class HTTPError < Exception
    end
    class HTTPNotFound < Exception
    end
  end
end