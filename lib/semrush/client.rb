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
  class UnknownError < StandardError; end;

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
    ALLOWED_METHODS = [:organic, :adwords, :organic_organic, :adwords_adwords, :adwords_organic, :organic_adwords]
    def method_missing(method, *args)
      return super unless ALLOWED_METHODS.include?(method)
      
      query = args.shift.to_s
      if query.empty?
        raise ArgumentError.new("Domain name, URL, or keywords are required.")
      end
      
      by(method, query, args.shift || {})
    end

    # The main report, with no "by"
    def report(q = "", options = {})
      request(q, options)
    end

    # Competitors actually uses by+organic_organic, which isn't nice to look at
    def competitors(q = "", options = {})
      by("organic_organic", q, options)
    end

    # Competitors adwords actually uses by+adwords_adwords, which isn't nice
    # to look at either
    def competitors_adwords(q = "", options = {})
      by("adwords_adwords", q, options)
    end

    # Potential ad/traffic buyers report
    def buyers(q = "", options = {})
      by("organic_adwords", q, options)
    end

    # Potential ad/traffic seller report
    def sellers(q = "", options = {})
      by("adwords_organic", q, options)
    end

    # Related keyword report
    def related_keywords(q = "", options = {})
      request("#{URI.escape(q)}+(related)", options)
    end

    # URL Report
    def url_report(q = "", options = {})
      q = "http://#{q}/" unless q.starts_with?("http")
      result = request(q, options)

      # A hash result means it just did a regular report, which isn't what we
      # want
      result.is_a?(Array) ? result : nil
    end

    private
      # Try to request using one of the (by+*) methods
      def by(type = "", q = "", options = {})
        request("#{q}+(by+#{type})", options)
      end

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
        e = /ERROR\s(\d+)\s::\s(.*)/.match(text) || {}
        name = (e[2] || "Unknown").titleize
        code = e[1] || -1
        error_class = name.gsub(/\s/, "") + "Error"

        if error_class == "NothingFoundError"
          nil
        else
          raise SEMRush.const_get(error_class).new("#{name} (#{code})")
        end
      end

      def parse(text = "")
        csv = CSV.parse(text.to_s, ";")
        data = {}
        format_key = lambda do |k|
          r = {
            /\s/ => "_",
            /[|\.|\)|\(]/ => "",
            /%/ => "percent",
            /\*/ => "times"
          }
          k = k.to_s.downcase
          r.each_pair {|pattern, replace| k.gsub!(pattern, replace) }
          k.to_sym
        end

        # (thanks http://snippets.dzone.com/posts/show/3899)
        keys = csv.shift.map(&format_key)
        string_data = csv.map {|row| row.map {|cell| cell.to_s } }
        string_data.map {|row| Hash[*keys.zip(row).flatten] }
      rescue CSV::IllegalFormatError => csvife
        tries ||= 0
        if (tries += 1) < 3
          retry
        else
          raise CSV::IllegalFormatError.new("Bad format for CSV: #{text.inspect}").tap{|e|
            e.set_backtrace(csvife.backtrace)}
        end
      end
  end
end
