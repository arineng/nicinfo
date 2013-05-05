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
    QueryType.add_item :BY_AS_NUMBER, "ASNUMBER"
    QueryType.add_item :BY_DOMAIN, "DOMAIN"
    QueryType.add_item :BY_RESULT, "RESULT"
    QueryType.add_item :BY_ENTITY_NAME, "ENTITYNAME"

  end

  # The main class for the nicinfo command.
  class Main

    def initialize args, config = nil

      if config
        @config = config
      else
        @config = NicInfo::Config.new(NicInfo::Config::formulate_app_data_dir())
      end

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
                "  result     - result from a previous query") do |type|
          uptype = type.upcase
          raise OptionParser::InvalidArgument, type.to_s unless QueryType.has_value?(uptype)
          @config.options.query_type = uptype
        end

        opts.on("--substring YES|NO|TRUE|FALSE",
                "Use substring matching for name searchs.") do |substring|
          @config.config[ NicInfo::SEARCH ][ NicInfo::SUBSTRING ] = false if substring =~ /no|false/i
          @config.config[ NicInfo::SEARCH ][ NicInfo::SUBSTRING ] = true if substring =~ /yes|true/i
          raise OptionParser::InvalidArgument, substring.to_s unless substring =~ /yes|no|true|false/i
        end

        opts.on("-U", "--url URL",
                "The base URL of the RDAP Service.") do |url|
          @config.options.base_url = url
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

        opts.on("--demo",
                "Populates the cache with demonstration results.") do |cc|
          @config.options.demo = true
        end

        opts.separator ""
        opts.separator "Output Options:"

        opts.on( "--messages MESSAGE_LEVEL",
                 "Specify the message level",
                 "  none - no messages are to be output",
                 "  some - some messages but not all",
                 "  all  - all messages to be outupt" ) do |m|
          config.logger.message_level = m.to_s.upcase
          begin
            config.logger.validate_message_level
          rescue
            raise OptionParser::InvalidArgument, m.to_s
          end
        end

        opts.on( "--messages-out FILE",
                 "FILE where messages will be written." ) do |f|
          config.logger.messages_out = f
        end

        opts.on( "--data DATA_AMOUNT",
                 "Specify the amount of data",
                 "  terse  - enough data to identify the object",
                 "  normal - normal view of data on objects",
                 "  extra  - all data about the object" ) do |d|
          config.logger.data_amount = d.to_s.upcase
          begin
            config.logger.validate_data_amount
          rescue
            raise OptionParser::InvalidArgument, d.to_s
          end
        end

        opts.on( "--data-out FILE",
                 "FILE where data will be written." ) do |f|
          config.logger.data_out = f
        end

        opts.on( "-V",
                 "Equivalent to --messages all and --data extra" ) do |v|
          config.logger.data_amount = NicInfo::DataAmount::EXTRA_DATA
          config.logger.message_level = NicInfo::MessageLevel::ALL_MESSAGES
        end

        opts.separator ""
        opts.separator "General Options:"

        opts.on( "-h", "--help",
                 "Show this message" ) do
          config.options.help = true
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
      elsif( @config.options.argv == nil || @config.options.argv == [] )
        if !@config.options.demo
          help()
        else
          exit
        end
      end


      if (@config.options.query_type == nil)
        @config.options.query_type = guess_query_value_type(@config.options.argv)
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
          when QueryType::BY_ENTITY_NAME
            @config.options.base_url = @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::ENTITY_ROOT_URL ]
        end
      end

      begin
        path = create_resource_url(@config.options.argv, @config.options.query_type)
        rdap_url = make_rdap_url( @config.options.base_url, path )
        #data = get( rdap_url )
        #root = REXML::Document.new(data).root
        #has_results = evaluate_response(root)
        #if has_results
        #  @config.logger.trace("Non-empty result set given.")
        #  show_helpful_messages(path)
        #end
        @config.logger.end_run
      rescue ArgumentError => a
        @config.logger.mesg(a.message)
      rescue Net::HTTPServerException => e
        case e.response.code
          when "404"
            @config.logger.mesg("Query yielded no results.")
          when "503"
            @config.logger.mesg("ARIN Whois-RWS is unavailable.")
        end
        @config.logger.trace("Server response code was " + e.response.code)
      end

    end

    def evaluate_response element
      has_results = false
      if (element.namespace == "http://www.arin.net/whoisrws/core/v1")
        case element.name
          when "net"
            net = NicInfo::Whois::WhoisNet.new(element)
            net.to_log(@config.logger)
            has_results = true
          when "poc"
            poc = NicInfo::Whois::WhoisPoc.new(element)
            poc.to_log(@config.logger)
            has_results = true
          when "org"
            org = NicInfo::Whois::WhoisOrg.new(element)
            org.to_log(@config.logger)
            has_results = true
          when "asn"
            asn = NicInfo::Whois::WhoisAsn.new(element)
            asn.to_log(@config.logger)
            has_results = true
          when "nets"
            has_results = handle_list_response(element)
          when "orgs"
            has_results = handle_list_response(element)
          when "pocs"
            has_results = handle_list_response(element)
          when "asns"
            has_results = handle_list_response(element)
          else
            @config.logger.mesg "Response contained an answer this program does not implement."
        end
      elsif (element.namespace == "http://www.arin.net/whoisrws/rdns/v1")
        case element.name
          when "delegation"
            del = NicInfo::Whois::WhoisRdns.new(element)
            del.to_log(@config.logger)
            has_results = true
          when "delegations"
            has_results = handle_list_response(element)
          else
            @config.logger.mesg "Response contained an answer this program does not implement."
        end
      elsif (element.namespace == "http://www.arin.net/whoisrws/pft/v1" && element.name == "pft")
        has_results = handle_pft_response element
      else
        @config.logger.mesg "Response contained an answer this program does not understand."
      end
      return has_results
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

    def handle_pft_response root
      objs = []
      root.elements.each("*/ref") do |ref|
        obj = nil
        case ref.parent.name
          when "net"
            obj = NicInfo::Whois::WhoisNet.new(ref.parent)
          when "poc"
            obj = NicInfo::Whois::WhoisPoc.new(ref.parent)
          when "org"
            obj = NicInfo::Whois::WhoisOrg.new(ref.parent)
          when "asn"
            obj = NicInfo::Whois::WhoisAsn.new(ref.parent)
          when "delegation"
            obj = NicInfo::Whois::WhoisRdns.new(ref.parent)
        end
        if (obj)
          copy_namespace_attributes(root, obj.element)
          @cache.create(obj.ref.to_s, obj.element)
          objs << obj
        end
      end
      tree = NicInfo::DataTree.new
      if (!objs.empty?)
        first = objs.first()
        tree_root = NicInfo::DataNode.new(first.to_s, first.ref.to_s)
        tree_root.add_child(NicInfo::Whois.make_orgs_tree(first.element))
        tree_root.add_child(NicInfo::Whois.make_pocs_tree(first.element))
        tree_root.add_child(NicInfo::Whois.make_asns_tree(first.element))
        tree_root.add_child(NicInfo::Whois.make_nets_tree(first.element))
        tree_root.add_child(NicInfo::Whois.make_delegations_tree(first.element))
        tree.add_root(tree_root)
      end
      if !tree_root.empty?
        tree.to_normal_log(@config.logger, true)
        @config.save_as_yaml(NicInfo::ARININFO_LASTTREE_YAML, tree)
      end
      objs.each do |obj|
        obj.to_log(@config.logger)
      end
      return true if !objs.empty? && !tree.empty?
      #else
      return false
    end

    def handle_list_response root
      objs = []
      root.elements.each("*/ref") do |ref|
        obj = nil
        case ref.parent.name
          when "net"
            obj = NicInfo::Whois::WhoisNet.new(ref.parent)
          when "poc"
            obj = NicInfo::Whois::WhoisPoc.new(ref.parent)
          when "org"
            obj = NicInfo::Whois::WhoisOrg.new(ref.parent)
          when "asn"
            obj = NicInfo::Whois::WhoisAsn.new(ref.parent)
          when "delegation"
            obj = NicInfo::Whois::WhoisRdns.new(ref.parent)
        end
        if (obj)
          copy_namespace_attributes(root, obj.element)
          @cache.create(obj.ref.to_s, obj.element)
          objs << obj
        end
      end

      tree = NicInfo::DataTree.new
      objs.each do |obj|
        tree_root = NicInfo::DataNode.new(obj.to_s, obj.ref.to_s)
        tree_root.add_child(NicInfo::Whois.make_orgs_tree(obj.element))
        tree_root.add_child(NicInfo::Whois.make_pocs_tree(obj.element))
        tree_root.add_child(NicInfo::Whois.make_asns_tree(obj.element))
        tree_root.add_child(NicInfo::Whois.make_nets_tree(obj.element))
        tree_root.add_child(NicInfo::Whois.make_delegations_tree(obj.element))
        tree.add_root(tree_root)
      end

      tree.add_children_as_root(NicInfo::Whois.make_orgs_tree(root))
      tree.add_children_as_root(NicInfo::Whois.make_pocs_tree(root))
      tree.add_children_as_root(NicInfo::Whois.make_asns_tree(root))
      tree.add_children_as_root(NicInfo::Whois.make_nets_tree(root))
      tree.add_children_as_root(NicInfo::Whois.make_delegations_tree(root))

      if !tree.empty?
        tree.to_terse_log(@config.logger, true)
        @config.save_as_yaml(NicInfo::ARININFO_LASTTREE_YAML, tree)
      end
      objs.each do |obj|
        obj.to_log(@config.logger)
      end if tree.empty?
      if tree.empty? && objs.empty?
        @config.logger.mesg("No results found.")
        has_results = false
      else
        has_results = true
        limit_element = REXML::XPath.first(root, "limitExceeded")
        if limit_element and limit_element.text() == "true"
          limit = limit_element.attribute("limit")
          @config.logger.mesg("Results limited to " + limit.to_s)
        end
      end
      return has_results
    end

    def copy_namespace_attributes(source, dest)
      source.attributes.each() do |name, value|
        if name.start_with?("xmlns")
          if !dest.attributes.get_attribute(name)
            dest.add_attribute(name, value)
          end
        end
      end
    end

    def show_helpful_messages path
      show_default_help = true
      case path
        when /rest\/net\/(.*)/
          net = $+
          if (!net.include?("/rdns"))
            new_net = net.sub("/pft", "")
            @config.logger.mesg('Use "arininfo -r dels ' + new_net + '" to see reverse DNS information.');
            show_default_help = false
          end
          if (!net.include?("/pft"))
            new_net = net.sub("/rdns", "")
            @config.logger.mesg('Use "arininfo --pft true ' + new_net + '" to see reverse DNS information.');
            show_default_help = false
          end
        when /rest\/org\/(.*)/
          org = $+
          if (!org.include?("/"))
            @config.logger.mesg('Use "arininfo --pft true ' + org + '-o" to see other relevant information.');
            show_default_help = false
          end
        when /rest\/ip\/(.*)/
          ip = $+
          if (ip.match(/\/pft/) == nil)
            @config.logger.mesg('Use "arininfo --pft true ' + ip + '" to see other relevant information.');
            show_default_help = false
          end
      end
      if show_default_help
        @config.logger.mesg('Use "arininfo -h" for help.')
      end
    end

  end

end

