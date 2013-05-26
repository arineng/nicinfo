# Copyright (C) 2011,2012,2013 American Registry for Internet Numbers
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
# IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.


require 'optparse'
require 'net/http'
require 'uri'
require 'config'
require 'constants'
require 'cache'
require 'enum'
require 'common_names'
require 'bootstrap'
require 'notices'
require 'entity'
require 'ip'
require 'ns'
require 'domain'
require 'autnum'
require 'ipaddr'
require 'data_tree'
begin
  require 'json'
rescue LoadError
  require 'rubygems'
  require 'json'
end

module NicInfo

  class QueryType < NicInfo::Enum

    QueryType.add_item :BY_IP4_ADDR, "IP4ADDR"
    QueryType.add_item :BY_IP6_ADDR, "IP6ADDR"
    QueryType.add_item :BY_IP4_CIDR, "IP4CIDR"
    QueryType.add_item :BY_IP6_CIDR, "IP6CIDR"
    QueryType.add_item :BY_IP, "IP"
    QueryType.add_item :BY_AS_NUMBER, "ASNUMBER"
    QueryType.add_item :BY_DOMAIN, "DOMAIN"
    QueryType.add_item :BY_RESULT, "RESULT"
    QueryType.add_item :BY_ENTITY_NAME, "ENTITYNAME"
    QueryType.add_item :BY_NAMESERVER, "NAMESERVER"

  end

  # The main class for the nicinfo command.
  class Main

    def initialize args, config = nil

      if config
        @config = config
      else
        @config = NicInfo::Config.new(NicInfo::Config::formulate_app_data_dir())
      end

      @config.options.require_query = true

      @opts = OptionParser.new do |opts|

        opts.banner = "Usage: nicinfo [options] QUERY_VALUE"

        opts.separator ""
        opts.separator "Query Options:"

        opts.on("-t", "--type TYPE",
                "Specify type of the query value.",
                "  ip4addr    - IPv4 address",
                "  ip6addr    - IPv6 address",
                "  ip4cidr    - IPv4 cidr block",
                "  ip6cidr    - IPv6 cidr block",
                "  asnumber   - autonomous system number",
                "  domain     - domain name",
                "  entityname - name of a contact, organization, registrar or other entity",
                "  nameserver - fully qualified domain name of a nameserver",
                "  result     - result from a previous query") do |type|
          uptype = type.upcase
          raise OptionParser::InvalidArgument, type.to_s unless QueryType.has_value?(uptype)
          @config.options.query_type = uptype
        end

        opts.on("-r", "--reverse",
                "Creates a reverse DNS name from an IP address. ") do |reverse|
          @config.options.reverse_ip = true
        end

        #opts.on("--substring YES|NO|TRUE|FALSE",
        #        "Use substring matching for name searchs.") do |substring|
        #  @config.config[ NicInfo::SEARCH ][ NicInfo::SUBSTRING ] = false if substring =~ /no|false/i
        #  @config.config[ NicInfo::SEARCH ][ NicInfo::SUBSTRING ] = true if substring =~ /yes|true/i
        #  raise OptionParser::InvalidArgument, substring.to_s unless substring =~ /yes|no|true|false/i
        #end

        opts.on("-b", "--base URL",
                "The base URL of the RDAP Service.") do |url|
          @config.options.base_url = url
        end

        opts.on("-u", "--url URL",
                "Fetch a specific RDAP URL.") do |url|
          @config.options.url = url
        end

        opts.separator ""
        opts.separator "Cache Options:"

        opts.on("--cache-expiry SECONDS",
                "Age in seconds of items in the cache to be considered expired.") do |s|
          @config.config[ NicInfo::CACHE ][ NicInfo::CACHE_EXPIRY ] = s
        end

        opts.on("--cache YES|NO|TRUE|FALSE",
                "Controls if the cache is used or not.") do |cc|
          @config.config[ NicInfo::CACHE ][ NicInfo::USE_CACHE ] = false if cc =~ /no|false/i
          @config.config[ NicInfo::CACHE ][ NicInfo::USE_CACHE ] = true if cc =~ /yes|true/i
          raise OptionParser::InvalidArgument, cc.to_s unless cc =~ /yes|no|true|false/i
        end

        opts.on("--empty-cache",
                "Empties the cache of all files regardless of eviction policy.") do |cc|
          @config.options.empty_cache = true
          @config.options.require_query = false
        end

        opts.on("--demo",
                "Populates the cache with demonstration results.") do |cc|
          @config.options.demo = true
          @config.options.require_query = false
        end

        opts.separator ""
        opts.separator "Output Options:"

        opts.on( "--messages MESSAGE_LEVEL",
                 "Specify the message level",
                 "  none - no messages are to be output",
                 "  some - some messages but not all",
                 "  all  - all messages to be outupt" ) do |m|
          @config.logger.message_level = m.to_s.upcase
          begin
            @config.logger.validate_message_level
          rescue
            raise OptionParser::InvalidArgument, m.to_s
          end
        end

        opts.on( "--messages-out FILE",
                 "FILE where messages will be written." ) do |f|
          @config.logger.messages_out = File.open( f, "w+" )
        end

        opts.on( "--data DATA_AMOUNT",
                 "Specify the amount of data",
                 "  terse  - enough data to identify the object",
                 "  normal - normal view of data on objects",
                 "  extra  - all data about the object" ) do |d|
          @config.logger.data_amount = d.to_s.upcase
          begin
            @config.logger.validate_data_amount
          rescue
            raise OptionParser::InvalidArgument, d.to_s
          end
        end

        opts.on( "--data-out FILE",
                 "FILE where data will be written." ) do |f|
          @config.logger.data_out = File.open( f, "w+" )
        end

        opts.on( "--pager YES|NO|TRUE|FALSE",
                 "Turns the pager on and off." ) do |pager|
          @config.logger.pager = false if pager =~ /no|false/i
          @config.logger.pager = true if pager =~ /yes|true/i
          raise OptionParser::InvalidArgument, pager.to_s unless pager =~ /yes|no|true|false/i
        end

        opts.on( "-V",
                 "Equivalent to --messages all and --data extra" ) do |v|
          @config.logger.data_amount = NicInfo::DataAmount::EXTRA_DATA
          @config.logger.message_level = NicInfo::MessageLevel::ALL_MESSAGES
        end

        opts.on( "-Q",
                 "Equivalent to --messages none and --data extra and --pager false" ) do |q|
          @config.logger.data_amount = NicInfo::DataAmount::EXTRA_DATA
          @config.logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
          @config.logger.pager = false
        end

        opts.on( "--json",
                 "Output raw JSON response." ) do |json|
          @config.options.output_json = true
        end

        opts.on( "--value VALUE",
                 "Outputs a specific JSON value." ) do |value|
          if !@config.options.json_values
            @config.options.json_values = Array.new
          end
          @config.options.json_values << value
        end

        opts.separator ""
        opts.separator "General Options:"

        opts.on( "-h", "--help",
                 "Show this message" ) do
          @config.options.help = true
          @config.options.require_query = false
        end

      end

      begin
        @opts.parse!(args)
      rescue OptionParser::InvalidArgument => e
        puts e.message
        puts "use -h for help"
        exit
      end
      @config.options.argv = args

    end

    def make_rdap_url( base_url, resource_path )
      if !(base_url.end_with?( "/" ))
        base_url << "/"
      end
      base_url << resource_path
    end

    # Do an HTTP GET with the path.
    def get url

      data = @cache.get(url)
      if (data == nil)

        @config.logger.trace("Issuing GET for " + url)
        req = Net::HTTP::Get.new(url)
        req["User-Agent"] = NicInfo::VERSION
        uri = URI.parse(url)
        res = Net::HTTP.start(uri.host, uri.port) do |http|
          http.request(req)
        end

        case res
          when Net::HTTPSuccess
            data = res.body
            @cache.create_or_update(url, data)
          else
            res.error!
        end

      end

      return data

    end

    def run

      @config.logger.run_pager
      @config.logger.mesg(NicInfo::VERSION)
      @config.setup_workspace
      @cache = Cache.new(@config)
      @cache.clean if @config.config[ NicInfo::CACHE ][ NicInfo::CLEAN_CACHE ]

      if @config.options.empty_cache
        @cache.empty
      end

      if @config.options.demo
        @config.logger.mesg( "Populating cache with demonstration results" )
        @config.logger.mesg( "Try the following demonstration queries:" )
        demo_dir = File.join( File.dirname( __FILE__ ), NicInfo::DEMO_DIR )
        demo_files = Dir::entries( demo_dir )
        demo_files.each do |file|
          df = File.join( demo_dir, file )
          if File.file?( df )
            demo_data = File.read( df )
            json_data = JSON.load demo_data
            demo_url = json_data[ NicInfo::NICINFO_DEMO_URL ]
            demo_hint = json_data[ NicInfo::NICINFO_DEMO_HINT ]
            @cache.create( demo_url, demo_data )
            @config.logger.mesg( "  " + demo_hint )
          end
        end
      end

      if(@config.options.help)
        help()
      end

      if @config.options.url
        @config.options.query_type = get_query_type_from_url( @config.options.url )
      end

      if @config.options.argv == nil || @config.options.argv == []
        if @config.options.require_query == false
          exit
        else
          help
        end
      end

      if (@config.options.query_type == nil)
        @config.options.query_type = guess_query_value_type(@config.options.argv)
        if (@config.options.query_type == QueryType::BY_IP4_ADDR ||
              @config.options.query_type == QueryType::BY_IP6_ADDR ) && @config.options.reverse_ip == true
          ip = IPAddr.new( @config.options.argv[ 0 ] )
          @config.options.argv[ 0 ] = ip.reverse
          @config.logger.mesg( "Query value changed to " + @config.options.argv[ 0 ] )
          @config.options.query_type = QueryType::BY_DOMAIN
        elsif @config.options.query_type == QueryType::BY_RESULT
          data_tree = @config.load_as_yaml( NicInfo::LASTTREE_YAML )
          @config.options.url = data_tree.find_rest_ref( @config.options.argv[ 0 ] )
          @config.options.query_type = get_query_type_from_url( @config.options.url )
        end
        if (@config.options.query_type == nil)
          @config.logger.mesg("Unable to guess type of query. You must specify it.")
          exit
        else
          @config.logger.mesg("Assuming query value is " + @config.options.query_type)
        end
      end

      if @config.options.base_url == nil
        bootstrap = Bootstrap.new( @config )
        case @config.options.query_type
          when QueryType::BY_IP4_ADDR
            @config.options.base_url = bootstrap.find_rir_url_by_ip( @config.options.argv[ 0 ] )
          when QueryType::BY_IP6_ADDR
            @config.options.base_url = bootstrap.find_rir_url_by_ip( @config.options.argv[ 0 ] )
          when QueryType::BY_IP4_CIDR
            @config.options.base_url = bootstrap.find_rir_url_by_ip( @config.options.argv[ 0 ] )
          when QueryType::BY_IP6_CIDR
            @config.options.base_url = bootstrap.find_rir_url_by_ip( @config.options.argv[ 0 ] )
          when QueryType::BY_AS_NUMBER
            @config.options.base_url = bootstrap.find_rir_url_by_as( @config.options.argv[ 0 ] )
          when QueryType::BY_DOMAIN
            @config.options.base_url = bootstrap.find_url_by_domain( @config.options.argv[ 0 ] )
          when QueryType::BY_NAMESERVER
            @config.options.base_url = bootstrap.find_url_by_domain( @config.options.argv[ 0 ] )
          when QueryType::BY_ENTITY_NAME
            @config.options.base_url = @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::ENTITY_ROOT_URL ]
        end
      end

      begin
        rdap_url = nil
        if !@config.options.url
          path = create_resource_url(@config.options.argv, @config.options.query_type)
          rdap_url = make_rdap_url( @config.options.base_url, path )
        else
          rdap_url = @config.options.url
        end
        data = get( rdap_url )
        json_data = JSON.load data
        inspect_rdap_compliance json_data
        cache_self_references json_data
        if @config.options.output_json
          @config.logger.raw( DataAmount::TERSE_DATA, data )
        elsif @config.options.json_values
          @config.options.json_values.each do |value|
            @config.logger.raw( DataAmount::TERSE_DATA, eval_json_value( value, json_data) )
          end
        else
          Notices.new.display_notices json_data, @config
          data_tree = DataTree.new( )
          case @config.options.query_type
            when QueryType::BY_IP4_ADDR
              NicInfo::display_ip( json_data, @config, data_tree )
            when QueryType::BY_IP6_ADDR
              NicInfo::display_ip( json_data, @config, data_tree )
            when QueryType::BY_IP4_CIDR
              NicInfo::display_ip( json_data, @config, data_tree )
            when QueryType::BY_IP6_CIDR
              NicInfo::display_ip( json_data, @config, data_tree )
            when QueryType::BY_IP
              NicInfo::display_ip( json_data, @config, data_tree )
            when QueryType::BY_AS_NUMBER
              NicInfo::display_autnum( json_data, @config, data_tree )
            when QueryType::BY_DOMAIN
              NicInfo::display_domain( json_data, @config, data_tree )
            when QueryType::BY_NAMESERVER
              NicInfo::display_ns( json_data, @config, data_tree )
            when QueryType::BY_ENTITY_NAME
              NicInfo::display_entity( json_data, @config )
          end
          @config.save_as_yaml( NicInfo::LASTTREE_YAML, data_tree ) if !data_tree.empty?
          show_helpful_messages rdap_url, data_tree
        end
        @config.logger.end_run
      rescue SocketError => a
        @config.logger.mesg(a.message)
      rescue ArgumentError => a
        @config.logger.mesg(a.message)
      rescue Net::HTTPServerException => e
        case e.response.code
          when "404"
            @config.logger.mesg("Query yielded no results.")
          when "503"
            @config.logger.mesg("RDAP service is unavailable.")
        end
        @config.logger.trace("Server response code was " + e.response.code)
      end

    end

    def inspect_rdap_compliance json
      rdap_conformance = json[ "rdapConformance" ]
      if rdap_conformance
        rdap_conformance.each do |conformance|
          @config.logger.trace( "Server conforms to #{conformance}" )
        end
      else
        @config.logger.trace( "Response has no RDAP Conformance level specified." )
      end
    end

    def help

      puts NicInfo::VERSION
      puts NicInfo::COPYRIGHT
      puts <<HELP_SUMMARY

NicInfo is a Registry Data Access Protocol (RDAP) client capable of querying RDAP
servers containing IP address, Autonomous System, and Domain name information.

The general usage is "nicinfo QUERY_VALUE" where the type of QUERY_VALUE influences the
type of query performed. This program will attempt to guess the type of QUERY_VALUE,
but the QUERY_VALUE type maybe explicitly set using the -t option.

Given the type of query to perform, this program will attempt to use the most appropriate
RDAP server it can determine, and follow referrals from that server if necessary.

HELP_SUMMARY
      puts @opts.help
      exit

    end

    # Evaluates the args and guesses at the type of query.
    # Args is an array of strings, most likely what is left
    # over after parsing ARGV
    def guess_query_value_type(args)
      retval = nil

      if (args.length() == 1)

        case args[0]
          when NicInfo::IPV4_REGEX
            retval = QueryType::BY_IP4_ADDR
          when NicInfo::IPV6_REGEX
            retval = QueryType::BY_IP6_ADDR
          when NicInfo::IPV6_HEXCOMPRESS_REGEX
            retval = QueryType::BY_IP6_ADDR
          when NicInfo::AS_REGEX
            retval = QueryType::BY_AS_NUMBER
          when NicInfo::ASN_REGEX
            old = args[0]
            args[0] = args[0].sub(/^AS/i, "")
            @config.logger.trace("Interpretting " + old + " as autonomous system number " + args[0])
            retval = QueryType::BY_AS_NUMBER
          when NicInfo::IP4_ARPA
            retval = QueryType::BY_DOMAIN
          when NicInfo::IP6_ARPA
            retval = QueryType::BY_DOMAIN
          when /(.*)\/\d/
            ip = $+
            if ip =~ NicInfo::IPV4_REGEX
              retval = QueryType::BY_IP4_CIDR
            elsif ip =~ NicInfo::IPV6_REGEX || ip =~ NicInfo::IPV6_HEXCOMPRESS_REGEX
              retval = QueryType::BY_IP6_CIDR
            end
          when NicInfo::DATA_TREE_ADDR_REGEX
            retval = QueryType::BY_RESULT
          when NicInfo::NS_REGEX
            retval = QueryType::BY_NAMESERVER
          when NicInfo::DOMAIN_REGEX
            retval = QueryType::BY_DOMAIN
          else
            if NicInfo::is_last_name(args[0].upcase)
              retval = QueryType::BY_ENTITY_NAME
            end
        end

      elsif (args.length() == 2)

        if NicInfo::is_last_name(args[1].upcase) && (NicInfo::is_male_name(args[0].upcase) || NicInfo::is_female_name(args[0].upcase))
          retval = QueryType::BY_ENTITY_NAME
        end

      elsif (args.length() == 3)

        if NicInfo::is_last_name(args[2].upcase) && (NicInfo::is_male_name(args[0].upcase) || NicInfo::is_female_name(args[0].upcase))
          retval = QueryType::BY_ENTITY_NAME
        end

      end

      return retval
    end

    # Creates a query type
    def create_resource_url(args, queryType)

      path = ""
      case queryType
        when QueryType::BY_IP4_ADDR
          path << "ip/" << args[0]
        when QueryType::BY_IP6_ADDR
          path << "ip/" << args[0]
        when QueryType::BY_IP4_CIDR
          path << "ip/" << args[0]
        when QueryType::BY_IP6_CIDR
          path << "ip/" << args[0]
        when QueryType::BY_AS_NUMBER
          path << "autnum/" << args[0]
        when QueryType::BY_NAMESERVER
          path << "nameserver/" << args[0]
        when QueryType::BY_DOMAIN
          path << "domain/" << args[0]
        when QueryType::BY_RESULT
          tree = @config.load_as_yaml(NicInfo::ARININFO_LASTTREE_YAML)
          path = tree.find_rest_ref(args[0])
          raise ArgumentError.new("Unable to find result for " + args[0]) unless path
        when QueryType::BY_ENTITY_NAME
          path << "entity/" << URI.escape( args[ 0 ] )
        else
          raise ArgumentError.new("Unable to create a resource URL for " + queryType)
      end

      return path
    end

    def get_query_type_from_url url
      queryType = nil
      case url
        when /.*\/ip\/.*/
          # covers all IP cases
          queryType = QueryType::BY_IP
        when /.*\/autnum\/.*/
          queryType = QueryType::BY_AS_NUMBER
        when /.*\/nameserver\/.*/
          queryType = QueryType::BY_NAMESERVER
        when /.*\/domain\/.*/
          queryType = QueryType::BY_DOMAIN
        when /.*\/entity\/.*/
          queryType = QueryType::BY_ENTITY_NAME
        else
          raise ArgumentError.new( "Unable to determine query type from url '#{url}'" )
      end
      return queryType
    end

    def eval_json_value json_value, json_data
      appended_code = String.new
      values = json_value.split( "." )
      values.each do |value|
        i = Integer( value ) rescue false
        if i
          appended_code << "[#{i}]"
        else
          appended_code << "[\"#{value}\"]"
        end
      end
      code = "json_data#{appended_code}"
      return eval( code )
    end

    def cache_self_references json_data
      links = NicInfo::get_links json_data
      if links
        self_link = NicInfo.get_self_link links
        if self_link
          pretty = JSON::pretty_generate( json_data )
          @cache.create( self_link, pretty )
        end
      end
      entities = NicInfo::get_entitites json_data
      entities.each do |entity|
        cache_self_references( entity )
      end if entities
      nameservers = NicInfo::get_nameservers json_data
      nameservers.each do |ns|
        cache_self_references( ns )
      end if nameservers
    end

    def show_helpful_messages rdap_url, data_tree
      arg = @config.options.argv[0]
      case @config.options.query_type
        when QueryType::BY_IP4_ADDR
          @config.logger.mesg("Use \"nicinfo -r #{arg}\" to see reverse DNS information.");
        when QueryType::BY_IP6_ADDR
          @config.logger.mesg("Use \"nicinfo -r #{arg}\" to see reverse DNS information.");
        when QueryType::BY_AS_NUMBER
          @config.logger.mesg("Use \"nicinfo #{arg}\" or \"nicinfo as#{arg}\" for autnums.");
      end
      if !data_tree.empty?
        @config.logger.mesg("Use \"nicinfo 1=\" to show #{data_tree.roots.first}")
      end
      @config.logger.mesg("Use \"nicinfo -u #{rdap_url}\" to directly query this resource in the future.")
      @config.logger.mesg('Use "nicinfo -h" for help.')
    end

  end

end

