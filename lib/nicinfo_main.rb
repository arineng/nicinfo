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
require 'rexml/document'
require 'base_opts'
require 'config'
require 'constants'
require 'cache'
require 'enum'
require 'whois_net'
require 'whois_poc'
require 'whois_org'
require 'whois_asn'
require 'whois_rdns'
require 'whois_trees'
require 'common_names'

module ARINcli

  module Whois

    class QueryType < ARINcli::Enum

      QueryType.add_item :BY_NET_HANDLE, "NETHANDLE"
      QueryType.add_item :BY_POC_HANDLE, "POCHANDLE"
      QueryType.add_item :BY_ORG_HANDLE, "ORGHANDLE"
      QueryType.add_item :BY_IP4_ADDR,   "IP4ADDR"
      QueryType.add_item :BY_IP6_ADDR,   "IP6ADDR"
      QueryType.add_item :BY_IP4_CIDR,   "IP4CIDR"
      QueryType.add_item :BY_IP6_CIDR,   "IP6CIDR"
      QueryType.add_item :BY_AS_NUMBER,  "ASNUMBER"
      QueryType.add_item :BY_DELEGATION, "DELEGATION"
      QueryType.add_item :BY_RESULT,     "RESULT"
      QueryType.add_item :BY_POC_NAME,   "POCNAME"
      QueryType.add_item :BY_ORG_NAME,   "ORGNAME"

    end

    class RelatedType < ARINcli::Enum

      RelatedType.add_item :NETS, "NETS"
      RelatedType.add_item :DELS, "DELS"
      RelatedType.add_item :ORGS, "ORGS"
      RelatedType.add_item :POCS, "POCS"
      RelatedType.add_item :ASNS, "ASNS"

    end

    class CidrMatching < ARINcli::Enum

      CidrMatching.add_item :EXACT, "EXACT"
      CidrMatching.add_item :LESS,  "LESS"
      CidrMatching.add_item :MORE,  "MORE"

    end

    # The main class for the arininfo command.
    class Main < ARINcli::BaseOpts

      def initialize args, config = nil

        if config
          @config = config
        else
          @config = ARINcli::Config.new( ARINcli::Config::formulate_app_data_dir() )
        end

        @opts = OptionParser.new do |opts|

          opts.banner = "Usage: arininfo [options] QUERY_VALUE"

          opts.separator ""
          opts.separator "Query Options:"

          opts.on( "-r", "--related TYPE",
            "Query for the specified type related to the query value.",
            "  nets - query for the related networks",
            "  dels - query for the reverse DNS delegations",
            "  orgs - query for the related organizations",
            "  pocs - query for the related points of contact",
            "  asns - query for the related autonomous system numbers") do |type|
            uptype = type.upcase
            raise OptionParser::InvalidArgument, type.to_s unless RelatedType.has_value?( uptype )
            @config.options.related_type = uptype
          end

          opts.on( "-t", "--type TYPE",
            "Specify type of the query value.",
            "  nethandle  - network handle",
            "  pochandle  - point of contact handle",
            "  orghandle  - organization handle",
            "  ip4addr    - IPv4 address",
            "  ip6addr    - IPv6 address",
            "  ip4cidr    - IPv4 cidr block",
            "  ip6cidr    - IPv6 cidr block",
            "  asnumber   - autonomous system number",
            "  delegation - reverse DNS delegation",
            "  pocname    - name of a point of contact",
            "  orgname    - name of an organization",
            "  result     - result from a previous query") do |type|
            uptype = type.upcase
            raise OptionParser::InvalidArgument, type.to_s unless QueryType.has_value?( uptype )
            @config.options.query_type = uptype
          end

          opts.on( "--pft YES|NO|TRUE|FALSE",
            "Use a PFT style query." ) do |pft|
            @config.config[ "whois" ][ "pft" ] = false if pft =~ /no|false/i
            @config.config[ "whois" ][ "pft" ] = true if pft =~ /yes|true/i
            raise OptionParser::InvalidArgument, pft.to_s unless pft =~ /yes|no|true|false/i
          end

          opts.on( "--cidr LESS|EXACT|MORE",
                   "Type of matching to use for CIDR queries." ) do |cidr|
            upcidr = cidr.upcase
            raise OptionParser::InvalidArgument, cidr.to_s unless CidrMatching.has_value?( upcidr )
            @config.config[ "whois" ][ "cidr" ] = upcidr
          end

          opts.on( "--substring YES|NO|TRUE|FALSE",
                   "Use substring matching for name searchs." ) do |substring|
            @config.config[ "whois" ][ "substring" ] = false if substring =~ /no|false/i
            @config.config[ "whois" ][ "substring" ] = true if substring =~ /yes|true/i
            raise OptionParser::InvalidArgument, substring.to_s unless substring =~ /yes|no|true|false/i
          end

          opts.on( "--details YES|NO|TRUE|FALSE",
                   "Query for extra details." ) do |details|
            @config.config[ "whois" ][ "details" ] = false if details =~ /no|false/i
            @config.config[ "whois" ][ "details" ] = true if details =~ /yes|true/i
            raise OptionParser::InvalidArgument, details.to_s unless details =~ /yes|no|true|false/i
          end

          opts.on( "-U", "--url URL",
            "The base URL of the Whois RESTful Web Service." ) do |url|
            @config.config[ "whois" ][ "url" ] = url
          end

          opts.separator ""
          opts.separator "Cache Options:"

          opts.on( "--cache-expiry SECONDS",
            "Age in seconds of items in the cache to be considered expired.") do |s|
            @config.config[ "whois" ][ "cache_expiry" ] = s
          end

          opts.on( "--cache YES|NO|TRUE|FALSE",
            "Controls if the cache is used or not." ) do |cc|
            @config.config[ "whois" ][ "use_cache" ] = false if cc =~ /no|false/i
            @config.config[ "whois" ][ "use_cache" ] = true if cc =~ /yes|true/i
            raise OptionParser::InvalidArgument, cc.to_s unless cc =~ /yes|no|true|false/i
          end

        end

        add_base_opts( @opts, @config )

        begin
          @opts.parse!( args )
        rescue OptionParser::InvalidArgument => e
          puts e.message
          puts "use -h for help"
          exit
        end
        @config.options.argv = args

      end

      # Do an HTTP GET with the path.
      # The base URL is taken from the config
      def get path

        if path.start_with?( "http://" )
          url = path
        else
          url = @config.config[ "whois" ][ "url" ]
          if( ! url.end_with?( "/" ) )
            url << "/"
          end
          url << path
        end

        data = @cache.get( url )
        if( data == nil )

          @config.logger.trace( "Issuing GET for " + url )
          req = Net::HTTP::Get.new( url )
          req[ "User-Agent" ] = ARINcli::VERSION
          uri = URI.parse( url )
          res = Net::HTTP.start( uri.host, uri.port ) do |http|
            http.request( req )
          end

          case res
            when Net::HTTPSuccess
              data = res.body
              @cache.create_or_update( url, data )
            else
              res.error!
          end

        end

        return data

      end

      def run

        if( @config.options.help )
          help()
        elsif( @config.options.argv == nil || @config.options.argv == [] )
          help()
        end

        @config.logger.run_pager
        @config.logger.mesg( ARINcli::VERSION )
        @config.setup_workspace
        @cache = ARINcli::Whois::Cache.new( @config )
        @cache.clean if @config.config[ "whois" ][ "clean_cache" ]

        if( @config.options.query_type == nil )
          @config.options.query_type = guess_query_value_type( @config.options.argv )
          if( @config.options.query_type == nil )
            @config.logger.mesg( "Unable to guess type of query. You must specify it." )
            exit
          else
            @config.logger.mesg( "Assuming query value is " + @config.options.query_type )
          end
        end

        begin
          path = create_resource_url( @config.options.argv, @config.options.query_type )
          path = mod_url( path, @config.options.related_type,
                          @config.config[ "whois" ][ "pft" ], @config.config[ "whois" ][ "details" ] )
          data = get( path )
          root = REXML::Document.new( data ).root
          has_results = evaluate_response( root )
          if has_results
            @config.logger.trace( "Non-empty result set given." )
            show_helpful_messages( path )
          end
          @config.logger.end_run
        rescue ArgumentError => a
          @config.logger.mesg( a.message )
        rescue Net::HTTPServerException => e
          case e.response.code
            when "404"
              @config.logger.mesg( "Query yielded no results." )
            when "503"
              @config.logger.mesg( "ARIN Whois-RWS is unavailable." )
          end
          @config.logger.trace( "Server response code was " + e.response.code )
        end

      end

      def evaluate_response element
        has_results = false
        if( element.namespace == "http://www.arin.net/whoisrws/core/v1" )
          case element.name
            when "net"
              net = ARINcli::Whois::WhoisNet.new( element )
              net.to_log( @config.logger )
              has_results = true
            when "poc"
              poc = ARINcli::Whois::WhoisPoc.new( element )
              poc.to_log( @config.logger )
              has_results = true
            when "org"
              org = ARINcli::Whois::WhoisOrg.new( element )
              org.to_log( @config.logger )
              has_results = true
            when "asn"
              asn = ARINcli::Whois::WhoisAsn.new( element )
              asn.to_log( @config.logger )
              has_results = true
            when "nets"
              has_results = handle_list_response( element )
            when "orgs"
              has_results = handle_list_response( element )
            when "pocs"
              has_results = handle_list_response( element )
            when "asns"
              has_results = handle_list_response( element )
            else
              @config.logger.mesg "Response contained an answer this program does not implement."
          end
        elsif( element.namespace == "http://www.arin.net/whoisrws/rdns/v1" )
          case element.name
            when "delegation"
              del = ARINcli::Whois::WhoisRdns.new( element )
              del.to_log( @config.logger )
              has_results = true
            when "delegations"
              has_results = handle_list_response( element )
            else
              @config.logger.mesg "Response contained an answer this program does not implement."
          end
        elsif( element.namespace == "http://www.arin.net/whoisrws/pft/v1" && element.name == "pft" )
          has_results = handle_pft_response element
        else
          @config.logger.mesg "Response contained an answer this program does not understand."
        end
        return has_results
      end

      def help

        puts ARINcli::VERSION
        puts ARINcli::COPYRIGHT
        puts <<HELP_SUMMARY

This program uses ARIN's Whois-RWS RESTful API to query ARIN's Whois database.
The general usage is "arininfo QUERY_VALUE" where the type of QUERY_VALUE influences the
type of query performed. This program will attempt to guess the type of QUERY_VALUE,
but the QUERY_VALUE type maybe explicitly set using the -t option. Queries for data
related to the QUERY_VALUE may be specified using the -r option (i.e. the reverse DNS
delegations related to a network).

In certain cases, Organization handles (orghandle), also knows as organization ids,
can be properly determined. This occurs when the Organization handle ends with '-z'
or with '-xxx' where xxx is a number. As a shortcut for Organization handles that do
not match these cases, a '-o' can be appended to signify that it is an Organization handle.

HELP_SUMMARY
        puts @opts.help
        exit

      end

      # Evaluates the args and guesses at the type of query.
      # Args is an array of strings, most likely what is left
      # over after parsing ARGV
      def guess_query_value_type( args )
        retval = nil

        if( args.length() == 1 )

          case args[ 0 ]
            when ARINcli::NET_HANDLE_REGEX
              args[ 0 ] = args[ 0 ].upcase
              retval = QueryType::BY_NET_HANDLE
            when ARINcli::NET6_HANDLE_REGEX
              args[ 0 ] = args[ 0 ].upcase
              retval = QueryType::BY_NET_HANDLE
            when ARINcli::POC_HANDLE_REGEX
              args[ 0 ] = args[ 0 ].upcase
              retval = QueryType::BY_POC_HANDLE
            when ARINcli::ORGL_HANDLE_REGEX
              args[ 0 ] = args[ 0 ].upcase
              retval = QueryType::BY_ORG_HANDLE
            when ARINcli::ORGN_HANDLE_REGEX
              args[ 0 ] = args[ 0 ].upcase
              retval = QueryType::BY_ORG_HANDLE
            when ARINcli::ORGS_HANDLE_REGEX
              old = args[ 0 ]
              args[ 0 ] = args[ 0 ].sub( /-O$/i, "" )
              args[ 0 ].upcase!
              @config.logger.trace( "Interpretting " + old + " as organization handle for " + args[ 0 ] )
              retval = QueryType::BY_ORG_HANDLE
            when ARINcli::IPV4_REGEX
              retval = QueryType::BY_IP4_ADDR
            when ARINcli::IPV6_REGEX
              retval = QueryType::BY_IP6_ADDR
            when ARINcli::IPV6_HEXCOMPRESS_REGEX
              retval = QueryType::BY_IP6_ADDR
            when ARINcli::AS_REGEX
              retval = QueryType::BY_AS_NUMBER
            when ARINcli::ASN_REGEX
              old = args[ 0 ]
              args[ 0 ] = args[ 0 ].sub( /^AS/i, "" )
              @config.logger.trace( "Interpretting " + old + " as autonomous system number " + args[ 0 ] )
              retval = QueryType::BY_AS_NUMBER
            when ARINcli::IP4_ARPA
              retval = QueryType::BY_DELEGATION
            when ARINcli::IP6_ARPA
              retval = QueryType::BY_DELEGATION
            when /(.*)\/\d/
              ip = $+
              if ip =~ ARINcli::IPV4_REGEX
                retval = QueryType::BY_IP4_CIDR
              elsif ip =~ ARINcli::IPV6_REGEX || ip =~ ARINcli::IPV6_HEXCOMPRESS_REGEX
                retval = QueryType::BY_IP6_CIDR
              end
            when ARINcli::DATA_TREE_ADDR_REGEX
              retval = QueryType::BY_RESULT
            else
              if ARINcli::is_last_name( args[ 0 ].upcase )
                retval = QueryType::BY_POC_NAME
              else
                retval = QueryType::BY_ORG_NAME
              end
          end

        elsif( args.length() == 2 )

          if ARINcli::is_last_name( args[ 1 ].upcase ) && ( ARINcli::is_male_name( args[ 0 ].upcase ) || ARINcli::is_female_name( args[ 0 ].upcase ) )
            retval = QueryType::BY_POC_NAME
          else
            retval = QueryType::BY_ORG_NAME
          end

        elsif( args.length() == 3 )

          if ARINcli::is_last_name( args[ 2 ].upcase ) && ( ARINcli::is_male_name( args[ 0 ].upcase ) || ARINcli::is_female_name( args[ 0 ].upcase ) )
            retval = QueryType::BY_POC_NAME
          else
            retval = QueryType::BY_ORG_NAME
          end

        else
          retval = QueryType::BY_ORG_NAME

        end

        return retval
      end

      # Creates a query type
      def create_resource_url( args, queryType )

        path = ""
        case queryType
          when QueryType::BY_NET_HANDLE
            path << "rest/net/" << args[ 0 ]
          when QueryType::BY_POC_HANDLE
            path << "rest/poc/" << args[ 0 ]
          when QueryType::BY_ORG_HANDLE
            path << "rest/org/" << args[ 0 ]
          when QueryType::BY_IP4_ADDR
            path << "rest/ip/" << args[ 0 ]
          when QueryType::BY_IP6_ADDR
            path << "rest/ip/" << args[ 0 ]
          when QueryType::BY_IP4_CIDR
            path << "rest/cidr/" << args[ 0 ]
          when QueryType::BY_IP6_CIDR
            path << "rest/cidr/" << args[ 0 ]
          when QueryType::BY_AS_NUMBER
            path << "rest/asn/" << args[ 0 ]
          when QueryType::BY_DELEGATION
            path << "rest/rdns/" << args[ 0 ]
          when QueryType::BY_RESULT
            tree = @config.load_as_yaml( ARINcli::ARININFO_LASTTREE_YAML )
            path = tree.find_rest_ref( args[ 0 ] )
            raise ArgumentError.new( "Unable to find result for " + args[ 0 ] ) unless path
          when QueryType::BY_POC_NAME
            substring = @config.config[ "whois" ][ "substring" ] ? "*" : ""
            path << "rest/pocs"
            case args.length
              when 1
                path << ";last=" << URI.escape( args[ 0 ] ) << substring
              when 2
                path << ";last=" << URI.escape( args[ 1 ] ) << substring << ";first=" << URI.escape( args[ 0 ] ) << substring
              when 3
                path << ";last=" << URI.escape( args[ 2 ] ) << substring << ";first=" << URI.escape( args[ 0 ] ) << substring << ";middle=" << URI.escape( args[ 1 ] ) << substring
              else
                path << ";q=" << URI.escape( args.join( " " ) ) << substring
            end
          when QueryType::BY_ORG_NAME
            substring = @config.config[ "whois" ][ "substring" ] ? "*" : ""
            path << "rest/orgs;q=" << URI.escape( args.join( " " ) ) << substring
          else
            raise ArgumentError.new( "Unable to create a resource URL for " + queryType )
        end

        return path
      end

      def mod_url( path, relatedType, pft, details )

        case path
          when /rest\/ip\//
            if relatedType != nil
              raise ArgumentError.new( "Unable to relate " + relatedType + " to " + path )
            else
              if pft
                path << "/pft"
              end
              if details
                path << "?showDetails=true"
              end
            end
          when /rest\/cidr\//
            if relatedType != nil
              raise ArgumentError.new( "Unable to relate " + relatedType + " to " + path )
            else
              cidr = @config.config[ "whois" ][ "cidr" ]
              if cidr == CidrMatching::LESS
                path << "/less"
              elsif cidr == CidrMatching::MORE
                path << "/more"
              end
            end
          when /rest\/net\//
            if relatedType == RelatedType::DELS
              path << "/rdns"
            elsif relatedType != nil
              raise ArgumentError.new( "Unable to relate " + relatedType + " to " + path )
            else
              if pft
                path << "/pft"
              end
              if details
                path << "?showDetails=true"
              end
            end
          when /rest\/rdns\//
            if relatedType == RelatedType::NETS
              path << "/nets"
            elsif relatedType != nil
              raise ArgumentError.new( "Unable to relate " + relatedType + " to " + path )
            end
          when /rest\/asn\//
            if relatedType != nil
              raise ArgumentError.new( "Unable to relate " + relatedType + " to " + path )
            else
              if details
                path << "?showDetails=true"
              end
            end
          when /rest\/org\//
            case relatedType
              when RelatedType::POCS
                path << "/pocs"
              when RelatedType::NETS
                path << "/nets"
              when RelatedType::ASNS
                path << "/asns"
              else
                raise ArgumentError.new( "Unable to relate " + relatedType + " to " + path ) if relatedType
            end
            if !relatedType and pft
              path << "/pft"
            end
            if details
              path << "?showDetails=true"
            end
          when /rest\/poc\//
            case relatedType
              when RelatedType::ORGS
                path << "/orgs"
              when RelatedType::NETS
                path << "/nets"
              when RelatedType::ASNS
                path << "/asns"
              else
                raise ArgumentError.new( "Unable to relate " + relatedType + " to " + path ) if relatedType
            end
            if details
              path << "?showDetails=true"
            end
        end

        return path
      end

      def handle_pft_response root
        objs = []
        root.elements.each( "*/ref" ) do |ref|
          obj = nil
          case ref.parent.name
            when "net"
              obj = ARINcli::Whois::WhoisNet.new( ref.parent )
            when "poc"
              obj = ARINcli::Whois::WhoisPoc.new( ref.parent )
            when "org"
              obj = ARINcli::Whois::WhoisOrg.new( ref.parent )
            when "asn"
              obj = ARINcli::Whois::WhoisAsn.new( ref.parent )
            when "delegation"
              obj = ARINcli::Whois::WhoisRdns.new( ref.parent )
          end
          if( obj )
            copy_namespace_attributes( root, obj.element )
            @cache.create( obj.ref.to_s, obj.element )
            objs << obj
          end
        end
        tree = ARINcli::DataTree.new
        if( !objs.empty? )
          first = objs.first()
          tree_root = ARINcli::DataNode.new( first.to_s, first.ref.to_s )
          tree_root.add_child( ARINcli::Whois.make_orgs_tree( first.element ) )
          tree_root.add_child( ARINcli::Whois.make_pocs_tree( first.element ) )
          tree_root.add_child( ARINcli::Whois.make_asns_tree( first.element ) )
          tree_root.add_child( ARINcli::Whois.make_nets_tree( first.element ) )
          tree_root.add_child( ARINcli::Whois.make_delegations_tree( first.element ) )
          tree.add_root( tree_root )
        end
        if !tree_root.empty?
          tree.to_normal_log( @config.logger, true )
          @config.save_as_yaml( ARINcli::ARININFO_LASTTREE_YAML, tree )
        end
        objs.each do |obj|
          obj.to_log( @config.logger )
        end
        return true if !objs.empty? && !tree.empty?
        #else
        return false
      end

      def handle_list_response root
        objs = []
        root.elements.each( "*/ref" ) do |ref|
          obj = nil
          case ref.parent.name
            when "net"
              obj = ARINcli::Whois::WhoisNet.new( ref.parent )
            when "poc"
              obj = ARINcli::Whois::WhoisPoc.new( ref.parent )
            when "org"
              obj = ARINcli::Whois::WhoisOrg.new( ref.parent )
            when "asn"
              obj = ARINcli::Whois::WhoisAsn.new( ref.parent )
            when "delegation"
              obj = ARINcli::Whois::WhoisRdns.new( ref.parent )
          end
          if( obj )
            copy_namespace_attributes( root, obj.element )
            @cache.create( obj.ref.to_s, obj.element )
            objs << obj
          end
        end

        tree = ARINcli::DataTree.new
        objs.each do |obj|
          tree_root = ARINcli::DataNode.new( obj.to_s, obj.ref.to_s )
          tree_root.add_child( ARINcli::Whois.make_orgs_tree( obj.element ) )
          tree_root.add_child( ARINcli::Whois.make_pocs_tree( obj.element ) )
          tree_root.add_child( ARINcli::Whois.make_asns_tree( obj.element ) )
          tree_root.add_child( ARINcli::Whois.make_nets_tree( obj.element ) )
          tree_root.add_child( ARINcli::Whois.make_delegations_tree( obj.element ) )
          tree.add_root( tree_root )
        end

        tree.add_children_as_root( ARINcli::Whois.make_orgs_tree( root ) )
        tree.add_children_as_root( ARINcli::Whois.make_pocs_tree( root ) )
        tree.add_children_as_root( ARINcli::Whois.make_asns_tree( root ) )
        tree.add_children_as_root( ARINcli::Whois.make_nets_tree( root ) )
        tree.add_children_as_root( ARINcli::Whois.make_delegations_tree( root ) )

        if !tree.empty?
          tree.to_terse_log( @config.logger, true )
          @config.save_as_yaml( ARINcli::ARININFO_LASTTREE_YAML, tree )
        end
        objs.each do |obj|
          obj.to_log( @config.logger )
        end if tree.empty?
        if tree.empty? && objs.empty?
          @config.logger.mesg( "No results found." )
          has_results = false
        else
          has_results = true
          limit_element = REXML::XPath.first( root, "limitExceeded")
          if limit_element and limit_element.text() == "true"
            limit = limit_element.attribute( "limit" )
            @config.logger.mesg( "Results limited to " + limit.to_s )
          end
        end
        return has_results
      end

      def copy_namespace_attributes( source, dest )
        source.attributes.each() do |name,value|
          if name.start_with?( "xmlns" )
            if !dest.attributes.get_attribute( name )
              dest.add_attribute( name, value )
            end
          end
        end
      end

      def show_helpful_messages path
        show_default_help = true
        case path
          when /rest\/net\/(.*)/
            net = $+
            if( ! net.include?( "/rdns" ) )
              new_net = net.sub( "/pft", "" )
              @config.logger.mesg( 'Use "arininfo -r dels ' + new_net + '" to see reverse DNS information.' );
              show_default_help = false
            end
            if( ! net.include?( "/pft" ) )
              new_net = net.sub( "/rdns", "" )
              @config.logger.mesg( 'Use "arininfo --pft true ' + new_net + '" to see reverse DNS information.' );
              show_default_help = false
            end
          when /rest\/org\/(.*)/
            org = $+
            if( ! org.include?( "/" ) )
              @config.logger.mesg( 'Use "arininfo --pft true ' + org + '-o" to see other relevant information.' );
              show_default_help = false
            end
          when /rest\/ip\/(.*)/
            ip = $+
            if( ip.match( /\/pft/ ) == nil )
              @config.logger.mesg( 'Use "arininfo --pft true ' + ip + '" to see other relevant information.' );
              show_default_help = false
            end
        end
        if show_default_help
          @config.logger.mesg( 'Use "arininfo -h" for help.' )
        end
      end

    end

  end

end

