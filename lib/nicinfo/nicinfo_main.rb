# Copyright (C) 2011-2017 American Registry for Internet Numbers
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
require 'net/https'
require 'uri'
require 'jcr'
require 'nicinfo/config'
require 'nicinfo/constants'
require 'nicinfo/cache'
require 'nicinfo/enum'
require 'nicinfo/common_names'
require 'nicinfo/bootstrap'
require 'nicinfo/notices'
require 'nicinfo/entity'
require 'nicinfo/ip'
require 'nicinfo/ns'
require 'nicinfo/domain'
require 'nicinfo/autnum'
require 'nicinfo/error_code'
require 'ipaddr'
require 'nicinfo/data_tree'
require 'nicinfo/traceroute'
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
    QueryType.add_item :BY_ENTITY_HANDLE, "ENTITYHANDLE"
    QueryType.add_item :BY_NAMESERVER, "NAMESERVER"
    QueryType.add_item :SRCH_ENTITY_BY_NAME, "ESBYNAME"
    QueryType.add_item :SRCH_DOMAINS, "DOMAINS"
    QueryType.add_item :SRCH_DOMAIN_BY_NAME, "DSBYNAME"
    QueryType.add_item :SRCH_DOMAIN_BY_NSNAME, "DSBYNSNAME"
    QueryType.add_item :SRCH_DOMAIN_BY_NSIP, "DSBYNSIP"
    QueryType.add_item :SRCH_NS, "NAMESERVERS"
    QueryType.add_item :SRCH_NS_BY_NAME, "NSBYNAME"
    QueryType.add_item :SRCH_NS_BY_IP, "NSBYIP"
    QueryType.add_item :TRACE, "TRACE"
    QueryType.add_item :BY_SERVER_HELP, "HELP"
    QueryType.add_item :BY_URL, "URL"

  end

  class JcrMode < NicInfo::Enum
    JcrMode.add_item :NO_VALIDATION, "NONE"
    JcrMode.add_item :STANDARD_VALIDATION, "STANDARD"
    JcrMode.add_item :STRICT_VALIDATION, "STRICT"
  end

  # The main class for the nicinfo command.
  class Main

    attr_accessor :config, :cache, :jcr_context, :jcr_strict_context

    def initialize args, config = nil

      if config
        @config = config
      else
        @config = NicInfo::Config.new(NicInfo::Config::formulate_app_data_dir())
      end

      @config.options.require_query = true
      @config.options.jcr = JcrMode::NO_VALIDATION

      @opts = OptionParser.new do |opts|

        opts.banner = "Usage: nicinfo [options] QUERY_VALUE"
        opts.version = NicInfo::VERSION

        opts.separator ""
        opts.separator "Query Options:"

        opts.on("-t", "--type TYPE",
                "Specify type of the query value.",
                "  ip4addr      - IPv4 address",
                "  ip6addr      - IPv6 address",
                "  ip4cidr      - IPv4 cidr block",
                "  ip6cidr      - IPv6 cidr block",
                "  asnumber     - autonomous system number",
                "  domain       - domain name",
                "  entityhandle - handle or id of a contact, organization, registrar or other entity",
                "  nameserver   - fully qualified domain name of a nameserver",
                "  result       - result from a previous query",
                "  esbyname     - entity search by name",
                "  dsbyname     - domain search by name",
                "  dsbynsname   - domain search by nameserver name",
                "  dsbynsip     - domain search by nameserver IP address",
                "  nsbyname     - nameserver search by nameserver name",
                "  nsbyip       - nameserver search by IP address",
                "  trace        - trace route",
                "  url          - RDAP URL",
                "  help         - server help") do |type|
          uptype = type.upcase
          raise OptionParser::InvalidArgument, type.to_s unless QueryType.has_value?(uptype)
          @config.options.query_type = uptype
          @config.options.require_query = false if uptype == "HELP"
        end

        opts.on("-r", "--reverse",
                "Creates a reverse DNS name from an IP address. ") do |reverse|
          @config.options.reverse_ip = true
        end

        opts.on("-b", "--base (or bootstrap) URL",
                "The base URL of the RDAP Service.",
                "When set, the internal bootstrap is bypassed.") do |url|
          @config.config[ NicInfo::BOOTSTRAP][ NicInfo::BOOTSTRAP_URL ] = url
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

        opts.on( "--color-scheme DARK|LIGHT|NONE",
                 "Determines color scheme to use:",
                 "  dark  - for terminals with dark backgrounds",
                 "  light - for terminals with light backgrounds",
                 "  none  - turn off colors" ) do |cs|
          @config.logger.color_scheme = cs.to_s.upcase
          raise OptionParser::InvalidArgument, cs.to_s unless cs =~ /dark|light|none/i
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
          unless @config.options.json_values
            @config.options.json_values = Array.new
          end
          @config.options.json_values << value
        end

        opts.separator ""
        opts.separator "Security Options:"

        opts.on( "--try-insecure YES|NO|TRUE|FALSE",
                 "Try HTTP if HTTPS fails" ) do |try_insecure|
          @config.config[ NicInfo::SECURITY ][ NicInfo::TRY_INSECURE ] = false if try_insecure =~ /no|false/i
          @config.config[ NicInfo::SECURITY ][ NicInfo::TRY_INSECURE ] = true if try_insecure =~ /yes|true/i
          raise OptionsParser::InvalidArgument, try_insecure.to_s unless try_insecure =~/yes|no|true|false/i
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

        opts.on( "--iana",
                 "Download RDAP bootstrap files from IANA" ) do
          @config.options.get_iana_files = true
          @config.options.require_query = false
        end

        opts.on( "--jcr STANDARD|STRICT",
                 "Validate RDAP response with JCR") do |mode|
          upmode = mode.upcase
          raise OptionParser::InvalidArgument, type.to_s unless JcrMode.has_value?(upmode)
          @config.options.jcr = upmode
          get_jcr_context if upmode == JcrMode::STANDARD_VALIDATION
          get_jcr_strict_context if upmode == JcrMode::STRICT_VALIDATION
        end

      end

      begin
        @opts.parse!(args)
      rescue OptionParser::InvalidOption => e
        puts e.message
        puts "use -h for help"
        exit
      rescue OptionParser::InvalidArgument => e
        puts e.message
        puts "use -h for help"
        exit
      rescue
        puts "Unable to parse command line options"
        puts "use -h for help"
        exit
      end
      @config.options.argv = args

    end

    def make_rdap_url( base_url, resource_path )
      unless base_url.end_with?("/")
        base_url << "/"
      end
      base_url << resource_path
    end

    # Do an HTTP GET with the path.
    def get url, try, expect_rdap = true

      data = @cache.get(url)
      if data == nil

        @config.logger.trace("Issuing GET for " + url)
        p = URI::Parser.new
        uri = URI.parse( p.escape( url ) )
        req = Net::HTTP::Get.new(uri.request_uri)
        req["User-Agent"] = NicInfo::VERSION_LABEL
        req["Accept"] = NicInfo::RDAP_CONTENT_TYPE + ", " + NicInfo::JSON_CONTENT_TYPE
        req["Connection"] = "close"
        http = Net::HTTP.new( uri.host, uri.port )
        if uri.scheme == "https"
          http.use_ssl=true
          http.verify_mode=OpenSSL::SSL::VERIFY_NONE
        end

        begin
          res = http.start do |http_req|
            http_req.request(req)
          end
        rescue OpenSSL::SSL::SSLError => e
          if @config.config[ NicInfo::SECURITY ][ NicInfo::TRY_INSECURE ]
            @config.logger.mesg( "Secure connection failed. Trying insecure connection." )
            uri.scheme = "http"
            return get( uri.to_s, try, expect_rdap )
          else
            raise e
          end
        end

        case res
          when Net::HTTPSuccess
            content_type = res[ "content-type" ].downcase
            if expect_rdap
              unless content_type.include?(NicInfo::RDAP_CONTENT_TYPE) or content_type.include?(NicInfo::JSON_CONTENT_TYPE)
                raise Net::HTTPServerException.new("Bad Content Type", res)
              end
              if content_type.include? NicInfo::JSON_CONTENT_TYPE
                @config.conf_msgs << "Server responded with non-RDAP content type but it is JSON"
              end
            end
            data = res.body
            @cache.create_or_update(url, data)
          else
            if res.code == "301" or res.code == "302" or res.code == "303" or res.code == "307" or res.code == "308"
              res.error! if try >= 5
              location = res["location"]
              return get( location, try + 1, expect_rdap)
            end
            res.error!
        end #end case

      end #end if

      return data

    end #end def

    # Do an HTTP GET of a file
    def get_file_via_http url, file_name, try

      @config.logger.trace("Downloading " + url + " to " + file_name )
      p = URI::Parser.new
      uri = URI.parse( p.escape( url ) )
      req = Net::HTTP::Get.new(uri.request_uri)
      req["User-Agent"] = NicInfo::VERSION_LABEL
      req["Accept"] = NicInfo::JSON_CONTENT_TYPE
      req["Connection"] = "close"
      http = Net::HTTP.new( uri.host, uri.port )
      if uri.scheme == "https"
        http.use_ssl=true
        http.verify_mode=OpenSSL::SSL::VERIFY_NONE
      end
      res = http.start do |http_req|
        http_req.request(req)
      end

      case res
        when Net::HTTPSuccess
          File.write(file_name, res.body)
        else
          if res.code == "301" or res.code == "302" or res.code == "303" or res.code == "307" or res.code == "308"
            res.error! if try >= 5
            location = res["location"]
            return get_file_via_http( location, file_name, try + 1)
          end
          res.error!
      end
    end


    def run

      @config.logger.run_pager
      @config.logger.mesg(NicInfo::VERSION_LABEL, NicInfo::AttentionType::PRIMARY )
      @config.setup_workspace
      @config.check_config_version
      @cache = Cache.new(@config)
      @cache.clean if @config.config[ NicInfo::CACHE ][ NicInfo::CLEAN_CACHE ]

      if @config.options.empty_cache
        @cache.empty
      end

      if @config.options.get_iana_files
        get_iana_files
      else
        check_bsfiles_age = @config.check_bsfiles_age?
        update_bsfiles = @config.update_bsfiles?( check_bsfiles_age )
        if update_bsfiles
          @config.logger.mesg( "IANA RDAP bootstrap files are old and need to be updated.", NicInfo::AttentionType::ERROR )
          get_iana_files
        elsif check_bsfiles_age
          @config.logger.mesg( "IANA RDAP bootstrap files are old. Update them with --iana option", NicInfo::AttentionType::ERROR )
        end
      end

      if @config.options.demo
        @config.logger.mesg( "Populating cache with demonstration results", NicInfo::AttentionType::INFO )
        @config.logger.mesg( "Try the following demonstration queries:", NicInfo::AttentionType::INFO )
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
            @config.logger.mesg( "  " + demo_hint, NicInfo::AttentionType::INFO )
          end
        end
      end

      if @config.options.help
        help()
      end

      if @config.options.argv == nil || @config.options.argv == [] && !@config.options.query_type
        unless @config.options.require_query
          return
        else
          help
        end
      end

      if @config.options.argv[0] == '.'
        @config.logger.mesg( "Obtaining current IP Address...")
        data = get("https://stat.ripe.net/data/whats-my-ip/data.json", 0, false )
        json_data = JSON.load(data)

        if json_data["data"] == nil || json_data["data"]["ip"] == nil
          @config.logger.mesg("Server repsonded with unknown JSON")
          @config.logger.mesg("Unable to determine your IP Address. You must specify it.")
          return
        elsif
          @config.logger.mesg("Your IP address is " + json_data["data"]["ip"], NicInfo::AttentionType::SUCCESS )
          @config.options.argv[0] = json_data["data"]["ip"]
        end
      end

      if @config.options.query_type == nil
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
            return
          end
        elsif @config.options.query_type == QueryType::BY_URL
          @config.options.url = @config.options.argv[0]
          @config.options.query_type = get_query_type_from_url( @config.options.url )
        else
          @config.options.externally_queriable = true
        end
        if @config.options.query_type == nil
          @config.logger.mesg("Unable to guess type of query. You must specify it.")
          return
        else
          @config.logger.trace("Assuming query value is " + @config.options.query_type)
        end
      end

      #determine if this will be a single query or multiple
      qtype = @config.options.query_type
      case qtype
        when QueryType::TRACE
          ips = NicInfo.traceroute @config.options.argv[ 0 ], @config
          if ips.empty?
            @config.logger.mesg "Trace route yeilded no data"
          else
            ips.each do |ip|
              @config.options.query_type = QueryType::BY_IP4_ADDR
              @config.options.argv[ 0 ] = ip
              @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::BOOTSTRAP_URL ] = nil
              json_data = do_rdap_query
              display_rdap_query( json_data, false )
            end
          end
        else
          json_data = do_rdap_query
          display_rdap_query( json_data, true ) if json_data
      end


    end

    def get_iana_files
      get_file_via_http("http://data.iana.org/rdap/asn.json", File.join(@config.rdap_bootstrap_dir, "asn.json"), 0)
      get_file_via_http("http://data.iana.org/rdap/ipv4.json", File.join(@config.rdap_bootstrap_dir, "ipv4.json"), 0)
      get_file_via_http("http://data.iana.org/rdap/ipv6.json", File.join(@config.rdap_bootstrap_dir, "ipv6.json"), 0)
      get_file_via_http("http://data.iana.org/rdap/dns.json", File.join(@config.rdap_bootstrap_dir, "dns.json"), 0)
      @config.set_bsfiles_last_update_time
    end

    def do_rdap_query
      retval = nil
      if @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::BOOTSTRAP_URL ] == nil && !@config.options.url
        bootstrap = Bootstrap.new( @config )
        qtype = @config.options.query_type
        if qtype == QueryType::BY_SERVER_HELP
          qtype = guess_query_value_type( @config.options.argv )
        end
        case qtype
          when QueryType::BY_IP4_ADDR
            @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::BOOTSTRAP_URL ] = bootstrap.find_url_by_ip( @config.options.argv[ 0 ] )
          when QueryType::BY_IP6_ADDR
            @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::BOOTSTRAP_URL ] = bootstrap.find_url_by_ip( @config.options.argv[ 0 ] )
          when QueryType::BY_IP4_CIDR
            @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::BOOTSTRAP_URL ] = bootstrap.find_url_by_ip( @config.options.argv[ 0 ] )
          when QueryType::BY_IP6_CIDR
            @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::BOOTSTRAP_URL ] = bootstrap.find_url_by_ip( @config.options.argv[ 0 ] )
          when QueryType::BY_AS_NUMBER
            @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::BOOTSTRAP_URL ] = bootstrap.find_url_by_as( @config.options.argv[ 0 ] )
          when QueryType::BY_DOMAIN
            @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::BOOTSTRAP_URL ] = bootstrap.find_url_by_domain( @config.options.argv[ 0 ] )
          when QueryType::BY_NAMESERVER
            @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::BOOTSTRAP_URL ] = bootstrap.find_url_by_domain( @config.options.argv[ 0 ] )
          when QueryType::BY_ENTITY_HANDLE
            @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::BOOTSTRAP_URL ] = bootstrap.find_url_by_entity( @config.options.argv[ 0 ] )
          when QueryType::SRCH_ENTITY_BY_NAME
            @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::BOOTSTRAP_URL ] = @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::ENTITY_ROOT_URL ]
          when QueryType::SRCH_DOMAIN_BY_NAME
            @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::BOOTSTRAP_URL ] = bootstrap.find_url_by_domain( @config.options.argv[ 0 ] )
          when QueryType::SRCH_DOMAIN_BY_NSNAME
            @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::BOOTSTRAP_URL ] = bootstrap.find_url_by_domain( @config.options.argv[ 0 ] )
          when QueryType::SRCH_DOMAIN_BY_NSIP
            @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::BOOTSTRAP_URL ] = @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::DOMAIN_ROOT_URL ]
          when QueryType::SRCH_NS_BY_NAME
            @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::BOOTSTRAP_URL ] = bootstrap.find_url_by_domain( @config.options.argv[ 0 ] )
          when QueryType::SRCH_NS_BY_IP
            @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::BOOTSTRAP_URL ] = bootstrap.find_url_by_ip( @config.options.argv[ 0 ] )
          else
            @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::BOOTSTRAP_URL ] = @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::HELP_ROOT_URL ]
        end
      end
      begin
        rdap_url = nil
        unless @config.options.url
          path = create_resource_url(@config.options.argv, @config.options.query_type)
          rdap_url = make_rdap_url(@config.config[NicInfo::BOOTSTRAP][NicInfo::BOOTSTRAP_URL], path)
        else
          rdap_url = @config.options.argv[0]
        end
        data = get( rdap_url, 0 )
        json_data = JSON.load data
        if (ec = json_data[ NicInfo::NICINFO_DEMO_ERROR ]) != nil
          res = MyHTTPResponse.new( "1.1", ec, "Demo Exception" )
          res["content-type"] = NicInfo::RDAP_CONTENT_TYPE
          res.body=data
          raise Net::HTTPServerException.new( "Demo Exception", res )
        end
        inspect_rdap_compliance json_data
        cache_self_references json_data
        retval = json_data
      rescue JSON::ParserError => a
        @config.logger.mesg( "Server returned invalid JSON!", NicInfo::AttentionType::ERROR )
      rescue SocketError => a
        @config.logger.mesg(a.message, NicInfo::AttentionType::ERROR )
      rescue ArgumentError => a
        @config.logger.mesg(a.message, NicInfo::AttentionType::ERROR )
      rescue Net::HTTPServerException => e
        case e.response.code
          when "200"
            @config.logger.mesg( e.message, NicInfo::AttentionType::SUCCESS )
          when "401"
            @config.logger.mesg("Authorization is required.", NicInfo::AttentionType::ERROR )
            handle_error_response e.response
          when "404"
            @config.logger.mesg("Query yielded no results.", NicInfo::AttentionType::INFO )
            handle_error_response e.response
          else
            @config.logger.mesg("Error #{e.response.code}.", NicInfo::AttentionType::ERROR )
            handle_error_response e.response
        end
        @config.logger.trace("Server response code was " + e.response.code)
      rescue Net::HTTPFatalError => e
        case e.response.code
          when "500"
            @config.logger.mesg("RDAP server is reporting an internal error.", NicInfo::AttentionType::ERROR )
            handle_error_response e.response
          when "501"
            @config.logger.mesg("RDAP server does not implement the query.", NicInfo::AttentionType::ERROR )
            handle_error_response e.response
          when "503"
            @config.logger.mesg("RDAP server is reporting that it is unavailable.", NicInfo::AttentionType::ERROR )
            handle_error_response e.response
          else
            @config.logger.mesg("Error #{e.response.code}.", NicInfo::AttentionType::ERROR )
            handle_error_response e.response
        end
        @config.logger.trace("Server response code was " + e.response.code)
      rescue Net::HTTPRetriableError => e
        @config.logger.mesg("Too many redirections, retries, or a redirect loop has been detected." )
      end

      return retval
    end

    def display_rdap_query json_data, show_help = true
      if @config.options.output_json
        @config.logger.raw( DataAmount::TERSE_DATA, JSON.generate( json_data ), false )
      elsif @config.options.json_values
        @config.options.json_values.each do |value|
          @config.logger.raw( DataAmount::TERSE_DATA, JSON.generate( eval_json_value( value, json_data) ), false )
        end
      else
        @config.factory.new_notices.display_notices json_data, @config.options.query_type == QueryType::BY_SERVER_HELP
        if @config.options.query_type != QueryType::BY_SERVER_HELP
          result_type = get_query_type_from_result( json_data )
          if result_type != nil
            if result_type != @config.options.query_type
              @config.logger.mesg( "Query type is " + @config.options.query_type + ". Result type is " + result_type + "." )
            else
              @config.logger.mesg( "Result type is " + result_type + "." )
            end
            @config.options.query_type = result_type
          elsif json_data[ "errorCode" ] == nil
            @config.conf_msgs << "Response has no result type."
          end
          data_tree = DataTree.new( )
          case @config.options.query_type
            when QueryType::BY_IP4_ADDR
              NicInfo::display_ip( json_data, @config, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_NETWORK )
            when QueryType::BY_IP6_ADDR
              NicInfo::display_ip( json_data, @config, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_NETWORK )
            when QueryType::BY_IP4_CIDR
              NicInfo::display_ip( json_data, @config, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_NETWORK )
            when QueryType::BY_IP6_CIDR
              NicInfo::display_ip( json_data, @config, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_NETWORK )
            when QueryType::BY_IP
              NicInfo::display_ip( json_data, @config, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_NETWORK )
            when QueryType::BY_AS_NUMBER
              NicInfo::display_autnum( json_data, @config, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_AUTNUM )
            when "NicInfo::DsData"
              NicInfo::display_ds_data( json_data, @config, data_tree )
            when "NicInfo::KeyData"
              NicInfo::display_key_data( json_data, @config, data_tree )
            when QueryType::BY_DOMAIN
              NicInfo::display_domain( json_data, @config, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_DOMAIN )
            when QueryType::BY_NAMESERVER
              NicInfo::display_ns( json_data, @config, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_NAMESERVER )
            when QueryType::BY_ENTITY_HANDLE
              NicInfo::display_entity( json_data, @config, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_ENTITY )
            when QueryType::SRCH_DOMAINS
              NicInfo::display_domains( json_data, @config, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_DOMAIN_SEARCH )
            when QueryType::SRCH_DOMAIN_BY_NAME
              NicInfo::display_domains( json_data, @config, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_DOMAIN_SEARCH )
            when QueryType::SRCH_DOMAIN_BY_NSNAME
              NicInfo::display_domains( json_data, @config, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_DOMAIN_SEARCH )
            when QueryType::SRCH_DOMAIN_BY_NSIP
              NicInfo::display_domains( json_data, @config, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_DOMAIN_SEARCH )
            when QueryType::SRCH_ENTITY_BY_NAME
              NicInfo::display_entities( json_data, @config, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_ENTITY_SEARCH )
            when QueryType::SRCH_NS
              NicInfo::display_nameservers( json_data, @config, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_NAMESERVER_SEARCH )
            when QueryType::SRCH_NS_BY_NAME
              NicInfo::display_nameservers( json_data, @config, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_NAMESERVER_SEARCH )
            when QueryType::SRCH_NS_BY_IP
              NicInfo::display_nameservers( json_data, @config, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_NAMESERVER_SEARCH )
          end
          @config.save_as_yaml( NicInfo::LASTTREE_YAML, data_tree ) if !data_tree.empty?
          show_search_results_truncated json_data
          show_conformance_messages
          show_helpful_messages json_data, data_tree if show_help
        end
      end
      @config.logger.end_run
    end

    def handle_error_response (res)
    if res["content-type"] == NicInfo::RDAP_CONTENT_TYPE && res.body && res.body.to_s.size > 0
        json_data = JSON.load( res.body )
        inspect_rdap_compliance json_data
        @config.factory.new_notices.display_notices json_data, true
        @config.factory.new_error_code.display_error_code( json_data )
      end
    end

    def inspect_rdap_compliance json
      rdap_conformance = json[ "rdapConformance" ]
      if rdap_conformance
        rdap_conformance.each do |conformance|
          @config.logger.trace( "Server conforms to #{conformance}", NicInfo::AttentionType::SECONDARY )
        end
      else
        @config.conf_msgs << "Response has no RDAP Conformance level specified."
      end
    end

    def get_jcr_context
      if @jcr_context != nil
        return @jcr_context
      end
      #else
      ruleset_file = File.join( File.dirname( __FILE__ ), NicInfo::JCR_DIR, NicInfo::RDAP_JCR )
      ruleset = File.open( ruleset_file ).read
      @jcr_context = JCR::Context.new(ruleset, false )
      return @jcr_context
    end

    def get_jcr_strict_context
      if @jcr_strict_context != nil
        return @jcr_strict_context
      end
      #else
      strict_file = File.join( File.dirname( __FILE__ ), NicInfo::JCR_DIR, NicInfo::STRICT_RDAP_JCR )
      strict = File.open( strict_file ).read
      rdap_context = get_jcr_context()
      @jcr_strict_context = rdap_context.override(strict )
      return @jcr_strict_context
    end

    def do_jcr( json_data, root_name )

      jcr_context = nil
      if config.options.jcr == JcrMode::STANDARD_VALIDATION
        config.logger.trace( "Standard JSON Content Rules validation mode enabled.")
        jcr_context = get_jcr_context()
      elsif config.options.jcr == JcrMode::STRICT_VALIDATION
        config.logger.trace( "Strict JSON Content Rules validation mode enabled.")
        jcr_context = get_jcr_strict_context()
      else
        return
      end

      e1 = jcr_context.evaluate( json_data, root_name )

      unless e1.success
        jcr_context.failure_report.each do |line|
          config.conf_msgs << line
        end
      else
        config.logger.trace( "JSON Content Rules validation was successful." )
      end
    end

    def help

      puts NicInfo::VERSION_LABEL
      puts NicInfo::COPYRIGHT
      puts <<HELP_SUMMARY

SYNOPSIS
  nicinfo [OPTIONS] QUERY_VALUE

SUMMARY
  NicInfo is a Registry Data Access Protocol (RDAP) client capable of querying RDAP
  servers containing IP address, Autonomous System, and Domain name information.

  The general usage is "nicinfo QUERY_VALUE" where the QUERY_VALUE is an IP address,
  autonomous system number, or domain name. The type of query to perform is implicitly
  determined but maybe explicitly set using the -t option. When the QUERY_VALUE is simply
  a dot or period character (e.g. "."), the IP address of the client is implied.

  Given the type of query to perform, this program will attempt to use the most appropriate
  RDAP server it can determine, and follow referrals from that server if necessary.

HELP_SUMMARY
      puts @opts.help
      puts EXTENDED_HELP
      exit

    end

    # Looks at the returned JSON and attempts to match that
    # to a query type.
    def get_query_type_from_result( json_data )
      retval = nil
      object_class_name = json_data[ "objectClassName" ]
      if object_class_name != nil
        case object_class_name
          when "domain"
            retval = QueryType::BY_DOMAIN
          when "ip network"
            retval = QueryType::BY_IP
          when "entity"
            retval = QueryType::BY_ENTITY_HANDLE
          when "autnum"
            retval = QueryType::BY_AS_NUMBER
          when "nameserver"
            retval = QueryType::BY_NAMESERVER
        end
      end
      if json_data[ "domainSearchResults" ]
        retval = QueryType::SRCH_DOMAINS
      elsif json_data[ "nameserverSearchResults" ]
        retval = QueryType::SRCH_NS
      elsif json_data[ "entitySearchResults" ]
        retval = QueryType::SRCH_ENTITY_BY_NAME
      end
      return retval
    end

    # Evaluates the args and guesses at the type of query.
    # Args is an array of strings, most likely what is left
    # over after parsing ARGV
    def guess_query_value_type(args)
      retval = nil

      if args.length() == 1

        case args[0]
          when NicInfo::URL_REGEX
            retval = QueryType::BY_URL
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
          when NicInfo::ENTITY_REGEX
            retval = QueryType::BY_ENTITY_HANDLE
          else
            last_name = args[ 0 ].sub( /\*/, '' ).upcase
            if NicInfo::is_last_name( last_name )
              retval = QueryType::SRCH_ENTITY_BY_NAME
            end
        end

      elsif args.length() == 2

        last_name = args[ 1 ].sub( /\*/, '' ).upcase
        first_name = args[ 0 ].sub( /\*/, '' ).upcase
        if NicInfo::is_last_name(last_name) && (NicInfo::is_male_name(first_name) || NicInfo::is_female_name(first_name))
          retval = QueryType::SRCH_ENTITY_BY_NAME
        end

      elsif args.length() == 3

        last_name = args[ 2 ].sub( /\*/, '' ).upcase
        first_name = args[ 0 ].sub( /\*/, '' ).upcase
        if NicInfo::is_last_name(last_name) && (NicInfo::is_male_name(first_name) || NicInfo::is_female_name(first_name))
          retval = QueryType::SRCH_ENTITY_BY_NAME
        end

      end

      return retval
    end

    # Creates a query type
    def create_resource_url(args, queryType)
      p = URI::Parser.new
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
        when QueryType::BY_ENTITY_HANDLE
          path << "entity/" << p.escape( args[ 0 ] )
        when QueryType::SRCH_ENTITY_BY_NAME
          case args.length
            when 1
              path << "entities?fn=" << p.escape( args[ 0 ] )
            when 2
              path << "entities?fn=" << p.escape( args[ 0 ] + " " + args[ 1 ] )
            when 3
              path << "entities?fn=" << p.escape( args[ 0 ] + " " + args[ 1 ] + " " + args[ 2 ] )
          end
        when QueryType::SRCH_DOMAIN_BY_NAME
          path << "domains?name=" << args[ 0 ]
        when QueryType::SRCH_DOMAIN_BY_NSNAME
          path << "domains?nsLdhName=" << args[ 0 ]
        when QueryType::SRCH_DOMAIN_BY_NSIP
          path << "domains?nsIp=" << args[ 0 ]
        when QueryType::SRCH_NS_BY_NAME
          path << "nameservers?name=" << args[ 0 ]
        when QueryType::SRCH_NS_BY_IP
          path << "nameservers?ip=" << args[ 0 ]
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
          queryType = QueryType::BY_ENTITY_HANDLE
        when /.*\/entities.*/
          queryType = QueryType::SRCH_ENTITY_BY_NAME
        when /.*\/domains.*/
          # covers all domain searches
          queryType = QueryType::SRCH_DOMAIN
        when /.*\/nameservers.*/
          # covers all nameserver searches
          queryType = QueryType::SRCH_NS
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
      links = NicInfo::get_links json_data, @config
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

    def show_conformance_messages
      return if @config.conf_msgs.size == 0
      @config.logger.mesg( "** WARNING: There are problems in the response that might cause some data to discarded. **", NicInfo::AttentionType::ERROR )
      i = 1
      pad = @config.conf_msgs.length.to_s.length
      @config.conf_msgs.each do |msg|
        @config.logger.trace( "#{i.to_s.rjust(pad," ")} : #{msg}", NicInfo::AttentionType::ERROR )
        i = i + 1
      end
    end

    def show_search_results_truncated json_data
      truncated = json_data[ "searchResultsTruncated" ]
      if truncated.instance_of?(TrueClass) || truncated.instance_of?(FalseClass)
        if truncated
          @config.logger.mesg( "Results have been truncated by the server.", NicInfo::AttentionType::INFO )
        end
      end
      if truncated != nil
        @config.conf_msgs << "'searchResultsTruncated' is not part of the RDAP specification and was removed before standardization."
      end
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
      unless data_tree.empty?
        @config.logger.mesg("Use \"nicinfo 1=\" to show #{data_tree.roots.first}")
        unless data_tree.roots.first.empty?
          children = data_tree.roots.first.children
          @config.logger.mesg("Use \"nicinfo 1.1=\" to show #{children.first}") if children.first.rest_ref
          if children.first != children.last
            len = children.length
            @config.logger.mesg("Use \"nicinfo 1.#{len}=\" to show #{children.last}") if children.last.rest_ref
          end
        end
      end
      self_link = NicInfo.get_self_link( NicInfo.get_links( json_data, @config ) )
      @config.logger.mesg("Use \"nicinfo #{self_link}\" to directly query this resource in the future.") if self_link and @config.options.externally_queriable
      @config.logger.mesg('Use "nicinfo -h" for help.')
    end

  end

  class MyHTTPResponse < Net::HTTPResponse
    attr_accessor :body
  end

  EXTENDED_HELP = <<EXTENDED_HELP

QUERIES
  For most query values, the query type is inferred. However, some types of queries
  cannot be inferred and so the -t parameter must be used. The domain search by name
  (dsbyname) and entity search by name (esbyname) queries can take wildcards ('*'),
  but these must be quoted or escaped to avoid processing by the invoking OS shell
  on Unix-like operating systems.

CONFIGURATION
  When this program is run for the first time, it creates a directory called .NicInfo
  (on Unix style platforms) or NicInfo (on Windows) in the users home directory. The
  home directory is determined by the $HOME environment variable on Unix style platforms
  and $APPDATA on Windows.

  A configuration file is created in this directory called config.yaml. This is a YAML
  file and contains a means for specifying most of the features of this program (instead
  of needing to specify them on the command line as options). To set the configuration
  back to the installation defaults, use the --reset option. This maybe desirable when
  updating versions of this program.

  A directory called rdap_cache is also created inside this directory. It holds cached
  values from previously executed queries.

CACHING
  This program will write query responses to a cache. By default, answers are pulled
  from the cache if present. This can be turned on or off with the --cache parameter or
  using the cache/use_cache value in the configuration file.

  Expiration of items in the cache and eviction of items from the cache can also be
  controlled. The cache can be manually emptied using the --empty-cache parameter.

BOOTSTRAPPING
  Bootstrapping is the process of finding an appropriate RDAP server in which to send
  queries. This program has a three tier bootstrapping process.

  The first tier looks up the most appropriate server using internal tables compiled
  from IANA registries. If an appropriate server cannot be found, bootstrapping falls
  to the second tier.

  The second tier has a default server for each type of RDAP query (domain, ip, autnum,
  nameserver, and entity). If this program cannot determine the type of query, bootstrapping
  falls to the third tier.

  The third tier is a default server for all queries.

  All bootstrap URLs are specified in the configuration file. Bootstrapping maybe
  bypassed using the -b or --base option (or by setting the bootstrap/base_url in the
  configuration file).

USAGE FOR SCRIPTING
  For usage with shell scripting, there are a couple of useful command line parameters.

  The --json parameter suppresses the human-readable output and instead emits the JSON
  returned by the server. When not writing to an output file, this options should be
  used with the -Q option to suppress the pager and program runtime messages so that
  the JSON maybe run through a JSON parser.

  The --jv parameter instructs this program to parse the JSON and emit specific JSON
  values.  This parameter is also useful in combination with the -Q option to feed the
  JSON values into other programs.  The syntax for specifying a JSON value is a
  list of JSON object member names or integers signifying JSON array indexes separated
  by a period, such as name1.name2.3.name4.5. For example, "entities.0.handle" would
  be useful for getting at the "handle" value from the following JSON:

    { "entities" : [ { "handle": "foo" } ] }

  Multiple --jv parameters may be specified.

DEMONSTRATION QUERIES
  There are several built-in demonstration queries that may be exercised to show the
  utility of RDAP. To use these queries, the --demo parameter must be used to populate
  the query answers into the cache. If the cache is already populated with items, it
  may be necessary to clean the cache using the --empty-cache parameter.

  When the --demo parameter is given, the list of demonstration queries will be printed
  out.

RDAP VALIDATION
  This program has built-in checks for verifying the validity of RDAP responses.
  Beyond these normal built-in checks, it can also JSON Content Rules to check
  the validity of the responses using the --jcr parameter, which requires either
  the standard (i.e. --jcr standard) or strict (i.e. --jcr strict) parameter
  options.

MORE INFORMATION
  More information about this program may be found at 
  https://github.com/arineng/nicinfo/wiki
EXTENDED_HELP

end


