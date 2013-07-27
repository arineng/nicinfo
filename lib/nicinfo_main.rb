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
require 'error_code'
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
    QueryType.add_item :BY_SERVER_HELP, "HELP"

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
        opts.version = NicInfo::VERSION

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
                "  result     - result from a previous query",
                "  help       - server help") do |type|
          uptype = type.upcase
          raise OptionParser::InvalidArgument, type.to_s unless QueryType.has_value?(uptype)
          @config.options.query_type = uptype
          @config.options.require_query = false if uptype == "HELP"
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

        opts.on("-b", "--base (or bootstrap) URL",
                "The base URL of the RDAP Service.",
                "When set, the internal bootstrap is bypassed.") do |url|
          @config.config[ NicInfo::BOOTSTRAP][ NicInfo::BOOTSTRAP_URL ] = url
        end

        opts.on("-u", "--url",
                "Fetch a specific RDAP URL.") do |url|
          @config.options.url = true
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

        opts.on( "--jv VALUE",
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

        opts.on( "--reset",
                 "Reset configuration to defaults" ) do
          @config.options.reset_config = true
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
    def get url, try

      data = @cache.get(url)
      if (data == nil)

        @config.logger.trace("Issuing GET for " + url)
        uri = URI.parse(url)
        req = Net::HTTP::Get.new(uri.request_uri)
        req["User-Agent"] = NicInfo::VERSION
        req["Accept"] = NicInfo::RDAP_CONTENT_TYPE + ", " + NicInfo::JSON_CONTENT_TYPE
        res = Net::HTTP.start(uri.host, uri.port) do |http|
          http.request(req)
        end

        case res
          when Net::HTTPSuccess
            content_type = res[ "content-type" ].downcase
            if !(content_type.include?(NicInfo::RDAP_CONTENT_TYPE) or content_type.include?(NicInfo::JSON_CONTENT_TYPE))
              raise Net::HTTPServerException.new( "Bad Content Type", res )
            end
            data = res.body
            @cache.create_or_update(url, data)
          else
            if res.code == "301" or res.code == "302" or res.code == "303" or res.code == "307" or res.code == "308"
              res.error! if try >= 5
              location = res["location"]
              return get( location, try + 1)
            end
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

      if @config.options.url and !@config.options.query_type
        @config.options.query_type = get_query_type_from_url( @config.options.argv[ 0 ] )
      end

      if @config.options.argv == nil || @config.options.argv == [] && !@config.options.query_type
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
          @config.options.argv[ 0 ] = ip.reverse.split( "\." )[ 1..-1 ].join( "." ) if ip.ipv4?
          @config.options.argv[ 0 ] = ip.reverse.split( "\." )[ 24..-1 ].join( "." ) if ip.ipv6?
          @config.logger.mesg( "Query value changed to " + @config.options.argv[ 0 ] )
          @config.options.query_type = QueryType::BY_DOMAIN
          @config.options.externally_queriable = true
        elsif @config.options.query_type == QueryType::BY_RESULT
          data_tree = @config.load_as_yaml( NicInfo::LASTTREE_YAML )
          node = data_tree.find_node( @config.options.argv[ 0 ] )
          if node and node.rest_ref
            @config.options.argv[ 0 ] = node.rest_ref
            @config.options.url = true
            if node.data_type
              @config.options.query_type = node.data_type
              @config.options.externally_queriable = false
            elsif node.rest_ref
              @config.options.query_type = get_query_type_from_url( node.rest_ref )
              @config.options.externally_queriable = true
            end
          else
            @config.logger.mesg( "#{@config.options.argv[0]} is not retrievable.")
            exit
          end
        else
          @config.options.externally_queriable = true
        end
        if (@config.options.query_type == nil)
          @config.logger.mesg("Unable to guess type of query. You must specify it.")
          exit
        else
          @config.logger.trace("Assuming query value is " + @config.options.query_type)
        end
      end

      if @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::BOOTSTRAP_URL ] == nil && !@config.options.url
        bootstrap = Bootstrap.new( @config )
        qtype = @config.options.query_type
        if qtype == QueryType::BY_SERVER_HELP
          qtype = guess_query_value_type( @config.options.argv )
        end
        case qtype
          when QueryType::BY_IP4_ADDR
            @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::BOOTSTRAP_URL ] = bootstrap.find_rir_url_by_ip( @config.options.argv[ 0 ] )
          when QueryType::BY_IP6_ADDR
            @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::BOOTSTRAP_URL ] = bootstrap.find_rir_url_by_ip( @config.options.argv[ 0 ] )
          when QueryType::BY_IP4_CIDR
            @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::BOOTSTRAP_URL ] = bootstrap.find_rir_url_by_ip( @config.options.argv[ 0 ] )
          when QueryType::BY_IP6_CIDR
            @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::BOOTSTRAP_URL ] = bootstrap.find_rir_url_by_ip( @config.options.argv[ 0 ] )
          when QueryType::BY_AS_NUMBER
            @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::BOOTSTRAP_URL ] = bootstrap.find_rir_url_by_as( @config.options.argv[ 0 ] )
          when QueryType::BY_DOMAIN
            @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::BOOTSTRAP_URL ] = bootstrap.find_url_by_domain( @config.options.argv[ 0 ] )
          when QueryType::BY_NAMESERVER
            @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::BOOTSTRAP_URL ] = bootstrap.find_url_by_domain( @config.options.argv[ 0 ] )
          when QueryType::BY_ENTITY_NAME
            @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::BOOTSTRAP_URL ] = @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::ENTITY_ROOT_URL ]
          else
            @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::BOOTSTRAP_URL ] = @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::HELP_ROOT_URL ]
        end
      end

      begin
        rdap_url = nil
        if !@config.options.url
          path = create_resource_url(@config.options.argv, @config.options.query_type)
          rdap_url = make_rdap_url( @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::BOOTSTRAP_URL ], path )
        else
          rdap_url = @config.options.argv[ 0 ]
        end
        data = get( URI::encode( rdap_url ), 0 )
        json_data = JSON.load data
        if (ec = json_data[ NicInfo::NICINFO_DEMO_ERROR ]) != nil
          res = MyHTTPResponse.new( "1.1", ec, "Demo Exception" )
          res["content-type"] = NicInfo::RDAP_CONTENT_TYPE
          res.body=data
          raise Net::HTTPServerException.new( "Demo Exception", res )
        end
        inspect_rdap_compliance json_data
        cache_self_references json_data
        if @config.options.output_json
          @config.logger.raw( DataAmount::TERSE_DATA, data )
        elsif @config.options.json_values
          @config.options.json_values.each do |value|
            @config.logger.raw( DataAmount::TERSE_DATA, eval_json_value( value, json_data) )
          end
        else
          Notices.new.display_notices json_data, @config, @config.options.query_type == QueryType::BY_SERVER_HELP
          if @config.options.query_type != QueryType::BY_SERVER_HELP
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
              when "NicInfo::DsData"
                NicInfo::display_ds_data( json_data, @config, data_tree )
              when "NicInfo::KeyData"
                NicInfo::display_key_data( json_data, @config, data_tree )
              when QueryType::BY_DOMAIN
                NicInfo::display_domain( json_data, @config, data_tree )
              when QueryType::BY_NAMESERVER
                NicInfo::display_ns( json_data, @config, data_tree )
              when QueryType::BY_ENTITY_NAME
                NicInfo::display_entity( json_data, @config, data_tree )
            end
            @config.save_as_yaml( NicInfo::LASTTREE_YAML, data_tree ) if !data_tree.empty?
            show_helpful_messages json_data, data_tree
          end
        end
        @config.logger.end_run
      rescue SocketError => a
        @config.logger.mesg(a.message)
      rescue ArgumentError => a
        @config.logger.mesg(a.message)
      rescue Net::HTTPServerException => e
        case e.response.code
          when "200"
            @config.logger.mesg( e.message )
          when "401"
            @config.logger.mesg("Authorization is required.")
            handle_error_response e.response
          when "404"
            @config.logger.mesg("Query yielded no results.")
            handle_error_response e.response
          when "503"
            @config.logger.mesg("RDAP service is unavailable.")
            handle_error_response e.response
          else
            @config.logger.mesg("Error #{e.response.code}.")
            handle_error_response e.response
        end
        @config.logger.trace("Server response code was " + e.response.code)
      rescue Net::HTTPFatalError => e
        case e.response.code
          when "500"
            @config.logger.mesg("RDAP server is reporting an internal error.")
            handle_error_response e.response
          else
            @config.logger.mesg("Error #{e.response.code}.")
            handle_error_response e.response
        end
        @config.logger.trace("Server response code was " + e.response.code)
      end

    end

    def handle_error_response (res)
    if res["content-type"] == NicInfo::RDAP_CONTENT_TYPE
        json_data = JSON.load( res.body )
        inspect_rdap_compliance json_data
        Notices.new.display_notices json_data, @config, true
        ErrorCode.new.display_error_code json_data, @config
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
        when QueryType::BY_SERVER_HELP
          path << "help"
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
        when /.*\/help.*/
          queryType = QueryType::BY_SERVER_HELP
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
      ds_data_objs = NicInfo::get_ds_data_objs json_data
      ds_data_objs.each do |ds|
        cache_self_references( ds )
      end if ds_data_objs
      key_data_objs = NicInfo::get_key_data_objs json_data
      key_data_objs.each do |key|
        cache_self_references( key )
      end if key_data_objs
    end

    def show_helpful_messages json_data, data_tree
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
        if !data_tree.roots.first.empty?
          children = data_tree.roots.first.children
          @config.logger.mesg("Use \"nicinfo 1.1=\" to show #{children.first}") if children.first.rest_ref
          if children.first != children.last
            len = children.length
            @config.logger.mesg("Use \"nicinfo 1.#{len}=\" to show #{children.last}") if children.last.rest_ref
          end
        end
      end
      self_link = NicInfo.get_self_link( NicInfo.get_links( json_data ) )
      @config.logger.mesg("Use \"nicinfo -u #{self_link}\" to directly query this resource in the future.") if self_link and @config.options.externally_queriable
      @config.logger.mesg('Use "nicinfo -h" for help.')
    end

  end

  class MyHTTPResponse < Net::HTTPResponse
    attr_accessor :body
  end

end

