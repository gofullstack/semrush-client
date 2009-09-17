require 'uri'
require 'net/http'
require 'csv'
require 'rubygems'
require 'activesupport'

module SEMRush
  class ArgumentError < ArgumentError; end;
  class ResponseError < StandardError; end;
  class ApiAccessDisabledError < ResponseError; end;
  class BadApiKeyError < ResponseError; end;
  class BadQueryError < ResponseError; end;
  class NothingFoundError < ResponseError; end;

  class Client
    VERSION = "0.0.1"
    API_HOST = "www.semrush.com"
    API_ENDPOINT = "/search.php?"

    def initialize(api_key = "")
      @api_key = api_key.to_s
      raise BadApiKeyError.new if @api_key.empty?
    end

    # The method missing tries to make the api call with the parenthized 
    # arguments (see samples on http://www.semrush.com/api.html)
    def method_missing(*args)
      method = args.shift.to_s
      q = args.shift.to_s || ""
      if q.empty?
        raise ArgumentError.new("Domain name, URL, or keywords are required") 
      end
      q += "+(by+#{method})"
      request(q, args.shift || {})
    end
    
    private
      def request(q = "", options = {})
        q = "q=#{q}"
        options.symbolize_keys!
        options[:key] = @api_key
        options[:uip] = options.delete(:ip)
        options.each_pair {|k, v| q += URI.escape("&#{k}=#{v}") unless v.nil? }

        response = Net::HTTP.start(API_HOST) do |http|
          http.get(API_ENDPOINT + q)
        end.body rescue "ERROR :: RESPONSE ERROR (-1)" # Make this error up
        response.starts_with?("ERROR") ? error(response) : parse(response)
      end

      # Format and raise an error
      def error(text = "")
        e = /ERROR\s(\d+)\s::\s(.*)/.match(text)
        name = e[2].titleize || "Unknown"
        code = e[1] || -1
        error_class = name.gsub(/\s/, "") + "Error"

        if error_class == "NothingFoundError"
          nil
        else
          raise SEMRush.const_get(error_class).new("#{name} (#{code})")
        end
      end

      def parse(text = "")
        nil if text.nil?
        # TODO: Parse CSV
        text
      end
  end
end
