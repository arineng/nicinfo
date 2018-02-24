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
require 'nicinfo/appctx'
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
require 'nicinfo/rdap_query'
require 'nicinfo/bulkip_infile'
require 'nicinfo/bulkip_data'
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

    attr_accessor :appctx, :jcr_context, :jcr_strict_context

    def initialize args, appctx = nil

      if appctx
        @appctx = appctx
      else
        @appctx = NicInfo::AppContext.new(NicInfo::AppContext::formulate_app_data_dir())
      end

      @appctx.options.require_query = true
      @appctx.options.jcr = JcrMode::NO_VALIDATION

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
          @appctx.options.query_type = uptype
          @appctx.options.require_query = false if uptype == "HELP"
        end

        opts.on("-r", "--reverse",
                "Creates a reverse DNS name from an IP address. ") do |reverse|
          @appctx.options.reverse_ip = true
        end

        opts.on("-b", "--base (or bootstrap) URL",
                "The base URL of the RDAP Service.",
                "When set, the internal bootstrap is bypassed.") do |url|
          @appctx.config[ NicInfo::BOOTSTRAP][ NicInfo::BOOTSTRAP_URL ] = url
        end

        opts.separator ""
        opts.separator "Cache Options:"

        opts.on("--cache-expiry SECONDS",
                "Age in seconds of items in the cache to be considered expired.") do |s|
          @appctx.config[ NicInfo::CACHE ][ NicInfo::CACHE_EXPIRY ] = s
        end

        opts.on("--cache YES|NO|TRUE|FALSE",
                "Controls if the cache is used or not.") do |cc|
          @appctx.config[ NicInfo::CACHE ][ NicInfo::USE_CACHE ] = false if cc =~ /no|false/i
          @appctx.config[ NicInfo::CACHE ][ NicInfo::USE_CACHE ] = true if cc =~ /yes|true/i
          raise OptionParser::InvalidArgument, cc.to_s unless cc =~ /yes|no|true|false/i
        end

        opts.on("--empty-cache",
                "Empties the cache of all files regardless of eviction policy.") do |cc|
          @appctx.options.empty_cache = true
          @appctx.options.require_query = false
        end

        opts.on("--demo",
                "Populates the cache with demonstration results.") do |cc|
          @appctx.options.demo = true
          @appctx.options.require_query = false
        end

        opts.separator ""
        opts.separator "Output Options:"

        opts.on( "--messages MESSAGE_LEVEL",
                 "Specify the message level",
                 "  none - no messages are to be output",
                 "  some - some messages but not all",
                 "  all  - all messages to be outupt" ) do |m|
          @appctx.logger.message_level = m.to_s.upcase
          begin
            @appctx.logger.validate_message_level
          rescue
            raise OptionParser::InvalidArgument, m.to_s
          end
        end

        opts.on( "--messages-out FILE",
                 "FILE where messages will be written." ) do |f|
          @appctx.logger.messages_out = File.open( f, "w+" )
        end

        opts.on( "--data DATA_AMOUNT",
                 "Specify the amount of data",
                 "  terse  - enough data to identify the object",
                 "  normal - normal view of data on objects",
                 "  extra  - all data about the object" ) do |d|
          @appctx.logger.data_amount = d.to_s.upcase
          begin
            @appctx.logger.validate_data_amount
          rescue
            raise OptionParser::InvalidArgument, d.to_s
          end
        end

        opts.on( "--data-out FILE",
                 "FILE where data will be written." ) do |f|
          @appctx.logger.data_out = File.open( f, "w+" )
        end

        opts.on( "--pager YES|NO|TRUE|FALSE",
                 "Turns the pager on and off." ) do |pager|
          @appctx.logger.pager = false if pager =~ /no|false/i
          @appctx.logger.pager = true if pager =~ /yes|true/i
          raise OptionParser::InvalidArgument, pager.to_s unless pager =~ /yes|no|true|false/i
        end

        opts.on( "--color-scheme DARK|LIGHT|NONE",
                 "Determines color scheme to use:",
                 "  dark  - for terminals with dark backgrounds",
                 "  light - for terminals with light backgrounds",
                 "  none  - turn off colors" ) do |cs|
          @appctx.logger.color_scheme = cs.to_s.upcase
          raise OptionParser::InvalidArgument, cs.to_s unless cs =~ /dark|light|none/i
        end

        opts.on( "-V",
                 "Equivalent to --messages all and --data extra" ) do |v|
          @appctx.logger.data_amount = NicInfo::DataAmount::EXTRA_DATA
          @appctx.logger.message_level = NicInfo::MessageLevel::ALL_MESSAGES
        end

        opts.on( "-Q",
                 "Equivalent to --messages none and --data extra and --pager false" ) do |q|
          @appctx.logger.data_amount = NicInfo::DataAmount::EXTRA_DATA
          @appctx.logger.message_level = NicInfo::MessageLevel::NO_MESSAGES
          @appctx.logger.pager = false
        end

        opts.on( "--json",
                 "Output raw JSON response." ) do |json|
          @appctx.options.output_json = true
        end

        opts.on( "--jv VALUE",
                 "Outputs a specific JSON value." ) do |value|
          unless @appctx.options.json_values
            @appctx.options.json_values = Array.new
          end
          @appctx.options.json_values << value
        end

        opts.on( "--pretty",
                 "Output JSON in a pretty format" ) do |pretty|
          @appctx.options.pretty = true
        end

        opts.separator ""
        opts.separator "Security Options:"

        opts.on( "--try-insecure YES|NO|TRUE|FALSE",
                 "Try HTTP if HTTPS fails" ) do |try_insecure|
          @appctx.config[ NicInfo::SECURITY ][ NicInfo::TRY_INSECURE ] = false if try_insecure =~ /no|false/i
          @appctx.config[NicInfo::SECURITY ][NicInfo::TRY_INSECURE ] = true if try_insecure =~ /yes|true/i
          raise OptionsParser::InvalidArgument, try_insecure.to_s unless try_insecure =~/yes|no|true|false/i
        end

        opts.separator ""
        opts.separator "General Options:"

        opts.on( "-h", "--help",
                 "Show this message" ) do
          @appctx.options.help = true
          @appctx.options.require_query = false
        end

        opts.on( "--reset",
                 "Reset configuration to defaults" ) do
          @appctx.options.reset_config = true
          @appctx.options.require_query = false
        end

        opts.on( "--iana",
                 "Download RDAP bootstrap files from IANA" ) do
          @appctx.options.get_iana_files = true
          @appctx.options.require_query = false
        end

        opts.on( "--jcr STANDARD|STRICT",
                 "Validate RDAP response with JCR") do |mode|
          upmode = mode.upcase
          raise OptionParser::InvalidArgument, type.to_s unless JcrMode.has_value?(upmode)
          @appctx.options.jcr = upmode
          get_jcr_context if upmode == JcrMode::STANDARD_VALIDATION
          get_jcr_strict_context if upmode == JcrMode::STRICT_VALIDATION
        end

        opts.separator ""
        opts.separator "Bulk IP Options:"

        opts.on( "--bulkip-in FILES",
                 "Bulk IP input files" ) do |files|
          @appctx.options.bulkip_in = files
          @appctx.options.do_bulkip = true
          @appctx.options.require_query = false
        end

        opts.on( "--bulkip-out-csv FILE",
                 "Bulk IP CSV output" ) do |file|
          @appctx.options.bulkip_out_csv = file
        end

        opts.on( "--bulkip-out-tsv FILE",
                 "Bulk IP TSV output" ) do |file|
          @appctx.options.bulkip_out_tsv = file
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
      @appctx.options.argv = args

    end

    # Do an HTTP GET of a file
    def get_file_via_http url, file_name, try

      @appctx.logger.trace("Downloading " + url + " to " + file_name )
      uri = URI.parse( URI::encode( url ) )
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

      @appctx.logger.run_pager
      @appctx.logger.mesg(NicInfo::VERSION_LABEL, NicInfo::AttentionType::PRIMARY )
      @appctx.setup_workspace
      @appctx.check_config_version
      @appctx.configure_cache

      if @appctx.options.empty_cache
        @appctx.cache.empty
      end

      if @appctx.options.get_iana_files
        get_iana_files
      else
        check_bsfiles_age = @appctx.check_bsfiles_age?
        update_bsfiles = @appctx.update_bsfiles?( check_bsfiles_age )
        if update_bsfiles
          @appctx.logger.mesg( "IANA RDAP bootstrap files are old and need to be updated.", NicInfo::AttentionType::ERROR )
          get_iana_files
        elsif check_bsfiles_age
          @appctx.logger.mesg( "IANA RDAP bootstrap files are old. Update them with --iana option", NicInfo::AttentionType::ERROR )
        end
      end

      if @appctx.options.demo
        @appctx.logger.mesg( "Populating cache with demonstration results", NicInfo::AttentionType::INFO )
        @appctx.logger.mesg( "Try the following demonstration queries:", NicInfo::AttentionType::INFO )
        demo_dir = File.join( File.dirname( __FILE__ ), NicInfo::DEMO_DIR )
        demo_files = Dir::entries( demo_dir )
        demo_files.each do |file|
          df = File.join( demo_dir, file )
          if File.file?( df )
            demo_data = File.read( df )
            json_data = JSON.load demo_data
            demo_url = json_data[ NicInfo::NICINFO_DEMO_URL ]
            demo_hint = json_data[ NicInfo::NICINFO_DEMO_HINT ]
            @appctx.cache.create( demo_url, demo_data )
            @appctx.logger.mesg( "  " + demo_hint, NicInfo::AttentionType::INFO )
          end
        end
      end

      if @appctx.options.help
        help()
      end

      if @appctx.options.do_bulkip
        do_bulkip()
      end

      if @appctx.options.argv == nil || @appctx.options.argv == [] && !@appctx.options.query_type
        unless @appctx.options.require_query
          return
        else
          help
        end
      end

      rdap_query = NicInfo::RDAPQuery.new( @appctx )
      guess = NicInfo::RDAPQueryGuess.new( @appctx )

      if @appctx.options.argv[0] == '.'
        @appctx.logger.mesg( "Obtaining current IP Address...")
        data = rdap_query.get("https://stat.ripe.net/data/whats-my-ip/data.json", 0, false )
        json_data = JSON.load(data)

        if json_data["data"] == nil || json_data["data"]["ip"] == nil
          @appctx.logger.mesg("Server repsonded with unknown JSON")
          @appctx.logger.mesg("Unable to determine your IP Address. You must specify it.")
          return
        elsif
          @appctx.logger.mesg("Your IP address is " + json_data["data"]["ip"], NicInfo::AttentionType::SUCCESS )
          @appctx.options.argv[0] = json_data["data"]["ip"]
        end
      end

      if @appctx.options.query_type == nil
        @appctx.options.query_type = guess.guess_query_value_type(@appctx.options.argv)
        if (@appctx.options.query_type == QueryType::BY_IP4_ADDR ||
              @appctx.options.query_type == QueryType::BY_IP6_ADDR ) && @appctx.options.reverse_ip == true
          ip = IPAddr.new( @appctx.options.argv[ 0 ] )
          @appctx.options.argv[ 0 ] = ip.reverse.split( "\." )[ 1..-1 ].join( "." ) if ip.ipv4?
          @appctx.options.argv[ 0 ] = ip.reverse.split( "\." )[ 24..-1 ].join( "." ) if ip.ipv6?
          @appctx.logger.mesg( "Query value changed to " + @appctx.options.argv[ 0 ] )
          @appctx.options.query_type = QueryType::BY_DOMAIN
          @appctx.options.externally_queriable = true
        elsif @appctx.options.query_type == QueryType::BY_RESULT
          data_tree = @appctx.load_as_yaml( NicInfo::LASTTREE_YAML )
          node = data_tree.find_node( @appctx.options.argv[ 0 ] )
          if node and node.rest_ref
            @appctx.options.argv[ 0 ] = node.rest_ref
            @appctx.options.url = true
            if node.data_type
              @appctx.options.query_type = node.data_type
              @appctx.options.externally_queriable = false
            elsif node.rest_ref
              @appctx.options.query_type = guess.get_query_type_from_url(node.rest_ref )
              @appctx.options.externally_queriable = true
            end
          else
            @appctx.logger.mesg( "#{@appctx.options.argv[0]} is not retrievable.")
            return
          end
        elsif @appctx.options.query_type == QueryType::BY_URL
          @appctx.options.url = @appctx.options.argv[0]
          @appctx.options.query_type = guess.get_query_type_from_url( @appctx.options.url )
        else
          @appctx.options.externally_queriable = true
        end
        if @appctx.options.query_type == nil
          @appctx.logger.mesg("Unable to guess type of query. You must specify it.")
          return
        else
          @appctx.logger.trace("Assuming query value is " + @appctx.options.query_type)
        end
      end

      #determine if this will be a single query or multiple
      qtype = @appctx.options.query_type
      case qtype
        when QueryType::TRACE
          ips = NicInfo.traceroute @appctx.options.argv[ 0 ], @appctx
          if ips.empty?
            @appctx.logger.mesg "Trace route yeilded no data"
          else
            ips.each do |ip|
              @appctx.options.query_type = QueryType::BY_IP4_ADDR
              @appctx.options.argv[ 0 ] = ip
              @appctx.config[ NicInfo::BOOTSTRAP ][ NicInfo::BOOTSTRAP_URL ] = nil
              rdap_response = rdap_query.do_rdap_query( @appctx.options.argv, @appctx.options.query_type, @appctx.options.url )
              if rdap_response.error_state
                show_error_response( rdap_response.json_data )
              else
                display_rdap_query( rdap_response.json_data, false ) if rdap_response.json_data
              end
            end
          end
        else
          rdap_response = rdap_query.do_rdap_query( @appctx.options.argv, @appctx.options.query_type, @appctx.options.url )
          if rdap_response.error_state
            show_error_response( rdap_response.json_data )
          else
            display_rdap_query( rdap_response.json_data, true ) if rdap_response.json_data
          end
      end


    end

    def get_iana_files
      get_file_via_http("http://data.iana.org/rdap/asn.json", File.join(@appctx.rdap_bootstrap_dir, "asn.json"), 0)
      get_file_via_http("http://data.iana.org/rdap/ipv4.json", File.join(@appctx.rdap_bootstrap_dir, "ipv4.json"), 0)
      get_file_via_http("http://data.iana.org/rdap/ipv6.json", File.join(@appctx.rdap_bootstrap_dir, "ipv6.json"), 0)
      get_file_via_http("http://data.iana.org/rdap/dns.json", File.join(@appctx.rdap_bootstrap_dir, "dns.json"), 0)
      @appctx.set_bsfiles_last_update_time
    end


    def display_rdap_query json_data, show_help = true
      unless do_json_output( json_data )
        @appctx.factory.new_notices.display_notices json_data, @appctx.options.query_type == QueryType::BY_SERVER_HELP
        if @appctx.options.query_type != QueryType::BY_SERVER_HELP
          result_type = get_query_type_from_result( json_data )
          if result_type != nil
            if result_type != @appctx.options.query_type
              @appctx.logger.mesg( "Query type is " + @appctx.options.query_type + ". Result type is " + result_type + "." )
            else
              @appctx.logger.mesg( "Result type is " + result_type + "." )
            end
            @appctx.options.query_type = result_type
          elsif json_data[ "errorCode" ] == nil
            @appctx.conf_msgs << "Response has no result type."
          end
          data_tree = DataTree.new( )
          case @appctx.options.query_type
            when QueryType::BY_IP4_ADDR
              NicInfo::display_ip(json_data, @appctx, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_NETWORK )
            when QueryType::BY_IP6_ADDR
              NicInfo::display_ip( json_data, @appctx, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_NETWORK )
            when QueryType::BY_IP4_CIDR
              NicInfo::display_ip( json_data, @appctx, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_NETWORK )
            when QueryType::BY_IP6_CIDR
              NicInfo::display_ip(json_data, @appctx, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_NETWORK )
            when QueryType::BY_IP
              NicInfo::display_ip(json_data, @appctx, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_NETWORK )
            when QueryType::BY_AS_NUMBER
              NicInfo::display_autnum( json_data, @appctx, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_AUTNUM )
            when "NicInfo::DsData"
              NicInfo::display_ds_data( json_data, @appctx, data_tree )
            when "NicInfo::KeyData"
              NicInfo::display_key_data( json_data, @appctx, data_tree )
            when QueryType::BY_DOMAIN
              NicInfo::display_domain( json_data, @appctx, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_DOMAIN )
            when QueryType::BY_NAMESERVER
              NicInfo::display_ns( json_data, @appctx, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_NAMESERVER )
            when QueryType::BY_ENTITY_HANDLE
              NicInfo::display_entity( json_data, @appctx, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_ENTITY )
            when QueryType::SRCH_DOMAINS
              NicInfo::display_domains( json_data, @appctx, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_DOMAIN_SEARCH )
            when QueryType::SRCH_DOMAIN_BY_NAME
              NicInfo::display_domains( json_data, @appctx, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_DOMAIN_SEARCH )
            when QueryType::SRCH_DOMAIN_BY_NSNAME
              NicInfo::display_domains( json_data, @appctx, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_DOMAIN_SEARCH )
            when QueryType::SRCH_DOMAIN_BY_NSIP
              NicInfo::display_domains( json_data, @appctx, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_DOMAIN_SEARCH )
            when QueryType::SRCH_ENTITY_BY_NAME
              NicInfo::display_entities( json_data, @appctx, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_ENTITY_SEARCH )
            when QueryType::SRCH_NS
              NicInfo::display_nameservers( json_data, @appctx, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_NAMESERVER_SEARCH )
            when QueryType::SRCH_NS_BY_NAME
              NicInfo::display_nameservers( json_data, @appctx, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_NAMESERVER_SEARCH )
            when QueryType::SRCH_NS_BY_IP
              NicInfo::display_nameservers( json_data, @appctx, data_tree )
              do_jcr( json_data, NicInfo::JCR_ROOT_NAMESERVER_SEARCH )
          end
          @appctx.save_as_yaml( NicInfo::LASTTREE_YAML, data_tree ) if !data_tree.empty?
          show_search_results_truncated json_data
          show_conformance_messages
          show_tracked_urls
          show_helpful_messages json_data, data_tree if show_help
        end
      end
      @appctx.logger.end_run
    end

    def do_json_output( json_data )
      retval = false

      if @appctx.options.output_json
        process_result( json_data )
        if @appctx.options.pretty
          o = JSON.pretty_generate( json_data )
        else
          o = JSON.generate( json_data )
        end
        @appctx.logger.raw( DataAmount::TERSE_DATA, o, false )
        retval = true
      elsif @appctx.options.json_values
        process_result( json_data )
        @appctx.options.json_values.each do |value|
          if @appctx.options.pretty
            o = JSON.pretty_generate( eval_json_value( value, json_data ) )
          else
            o = JSON.generate( eval_json_value( value, json_data ) )
          end
          @appctx.logger.raw( DataAmount::TERSE_DATA, o, false )
        end
        retval = true
      end
      return retval
    end

    def show_error_response( json_data )
      if json_data
        @appctx.factory.new_notices.display_notices json_data, true
        @appctx.factory.new_error_code.display_error_code( json_data )
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
      if @appctx.options.jcr == JcrMode::STANDARD_VALIDATION
        @appctx.logger.trace( "Standard JSON Content Rules validation mode enabled.")
        jcr_context = get_jcr_context()
      elsif @appctx.options.jcr == JcrMode::STRICT_VALIDATION
        @appctx.logger.trace( "Strict JSON Content Rules validation mode enabled.")
        jcr_context = get_jcr_strict_context()
      else
        return
      end

      e1 = jcr_context.evaluate( json_data, root_name )

      unless e1.success
        jcr_context.failure_report.each do |line|
          @appctx.conf_msgs << line
        end
      else
        @appctx.logger.trace( "JSON Content Rules validation was successful." )
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

    def process_result( json_data )
      success = false
      type = get_query_type_from_result( json_data )
      case type
        when QueryType::BY_IP
          NicInfo::process_ip(json_data, @appctx )
          do_jcr( json_data, NicInfo::JCR_ROOT_NETWORK )
        when QueryType::BY_AS_NUMBER
          NicInfo::process_autnum( json_data, @appctx )
          do_jcr( json_data, NicInfo::JCR_ROOT_AUTNUM )
        when QueryType::BY_DOMAIN
          NicInfo::process_domain( json_data, @appctx )
          do_jcr( json_data, NicInfo::JCR_ROOT_DOMAIN )
        when QueryType::BY_NAMESERVER
          NicInfo::process_ns( json_data, @appctx )
          do_jcr( json_data, NicInfo::JCR_ROOT_NAMESERVER )
        when QueryType::BY_ENTITY_HANDLE
          NicInfo::process_entity( json_data, @appctx )
          do_jcr( json_data, NicInfo::JCR_ROOT_ENTITY )
        when QueryType::SRCH_DOMAINS
          do_jcr( json_data, NicInfo::JCR_ROOT_DOMAIN_SEARCH )
        when QueryType::SRCH_NS
          do_jcr( json_data, NicInfo::JCR_ROOT_NAMESERVER_SEARCH )
      end
      return success
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


    def show_conformance_messages
      return if @appctx.conf_msgs.size == 0
      @appctx.logger.mesg( "** WARNING: There are problems in the response that might cause some data to discarded. **", NicInfo::AttentionType::ERROR )
      i = 1
      pad = @appctx.conf_msgs.length.to_s.length
      @appctx.conf_msgs.each do |msg|
        @appctx.logger.trace( "#{i.to_s.rjust(pad," ")} : #{msg}", NicInfo::AttentionType::ERROR )
        i = i + 1
      end
    end

    def show_tracked_urls
      @appctx.tracked_urls.each_value do |tracker|
        qps = tracker.total_queries.fdiv( tracker.last_query_time.to_i - tracker.first_query_time.to_i )
        @appctx.logger.trace( "#{tracker.total_queries} queries to #{tracker.url} rated at #{qps} queries per second")
      end
    end

    def show_search_results_truncated json_data
      truncated = json_data[ "searchResultsTruncated" ]
      if truncated.instance_of?(TrueClass) || truncated.instance_of?(FalseClass)
        if truncated
          @appctx.logger.mesg( "Results have been truncated by the server.", NicInfo::AttentionType::INFO )
        end
      end
      if truncated != nil
        @appctx.conf_msgs << "'searchResultsTruncated' is not part of the RDAP specification and was removed before standardization."
      end
    end

    def show_helpful_messages json_data, data_tree
      arg = @appctx.options.argv[0]
      case @appctx.options.query_type
        when QueryType::BY_IP4_ADDR
          @appctx.logger.mesg("Use \"nicinfo -r #{arg}\" to see reverse DNS information.");
        when QueryType::BY_IP6_ADDR
          @appctx.logger.mesg("Use \"nicinfo -r #{arg}\" to see reverse DNS information.");
        when QueryType::BY_AS_NUMBER
          @appctx.logger.mesg("Use \"nicinfo #{arg}\" or \"nicinfo as#{arg}\" for autnums.");
      end
      unless data_tree.empty?
        @appctx.logger.mesg("Use \"nicinfo 1=\" to show #{data_tree.roots.first}")
        unless data_tree.roots.first.empty?
          children = data_tree.roots.first.children
          @appctx.logger.mesg("Use \"nicinfo 1.1=\" to show #{children.first}") if children.first.rest_ref
          if children.first != children.last
            len = children.length
            @appctx.logger.mesg("Use \"nicinfo 1.#{len}=\" to show #{children.last}") if children.last.rest_ref
          end
        end
      end
      self_link = NicInfo.get_self_link( NicInfo.get_links( json_data, @appctx ) )
      @appctx.logger.mesg("Use \"nicinfo #{self_link}\" to directly query this resource in the future.") if self_link and @appctx.options.externally_queriable
      @appctx.logger.mesg('Use "nicinfo -h" for help.')
    end

    def do_bulkip
      file_list = @appctx.options.bulkip_in
      if File.directory?( file_list )
        file_list = file_list + File::SEPARATOR unless file_list.end_with?( File::SEPARATOR )
        file_list = file_list + "*"
      end
      Dir.glob( file_list ).each do |file|
        b = BulkIPInFile.new( file )
        if !b.has_strategy
          raise ArgumentError.new( "cannot determine parsing strategy for #{file}")
        end
        @appctx.logger.trace( "file #{file} strategry is #{b.strategy}")
      end
      rdap_query = NicInfo::RDAPQuery.new( @appctx )
      bulkip_data = NicInfo::BulkIPData.new( @appctx )
      Dir.glob( file_list ).each do |file|
        @appctx.logger.mesg( "Processing #{file}")
        b = BulkIPInFile.new( file )
        b.foreach do |ip,time|
          @appctx.logger.trace( "bulk ip: #{ip} time: #{time}")
          begin
            ipaddr = IPAddr.new( ip )
            unless bulkip_data.valid_to_query?( ipaddr )
              @appctx.logger.trace( "skipping non-global-unicast address #{ip}")
            else
              if !bulkip_data.hit_ipaddr( ipaddr, time )
                query_value = [ ip ]
                qtype = QueryType::BY_IP4_ADDR
                qtype = QueryType::BY_IP6_ADDR if ipaddr.ipv6?
                rdap_response = rdap_query.do_rdap_query( query_value, qtype, nil )
                unless rdap_response.error_state
                  rtype = get_query_type_from_result( rdap_response.json_data )
                  if rtype == QueryType::BY_IP
                    ipnetwork = NicInfo::process_ip( rdap_response.json_data, @appctx )
                    bulkip_data.hit_network( ipnetwork )
                  else
                    bulkip_data.fetch_error( ipaddr, time )
                  end
                else
                  bulkip_data.fetch_error( ipaddr, time )
                end
              else
                @appctx.logger.trace( "skipping #{ip} because network has already been retreived")
              end
            end
          rescue IPAddr::InvalidAddressError
            bulkip_data.ip_error( ip )
            @appctx.logger.mesg( "Invalid IP address #{ip}", NicInfo::AttentionType::ERROR )
          end
        end
      end
      bulkip_data.review_fetch_errors
      if @appctx.options.bulkip_out_csv
        bulkip_data.output_csv( @appctx.options.bulkip_out_csv )
      end
      if @appctx.options.bulkip_out_tsv
        bulkip_data.output_tsv( @appctx.options.bulkip_out_tsv )
      end
      show_tracked_urls
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


