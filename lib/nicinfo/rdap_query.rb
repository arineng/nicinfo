# Copyright (C) 2018 American Registry for Internet Numbers
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

module NicInfo

  class RDAPResponse

    attr_accessor :data, :json_data, :exception, :error_state, :response, :code

  end

  class TrackedUrl

    attr_accessor :url, :total_queries, :first_query_time, :last_query_time

    def initialize( url )
      @url = url
      @total_queries = 1
      @first_query_time = Time.now
      @last_query_time = Time.now
    end

    def queried
      @total_queries = @total_queries + 1
      @last_query_time = Time.now
    end

  end

  class RDAPQuery

    attr_accessor :appctx

    def initialize( appctx )
      @appctx = appctx
    end

    def do_rdap_query( query, qtype, explicit_url )
      retval = RDAPResponse.new
      bootstrap_url = nil
      if @appctx.config[ NicInfo::BOOTSTRAP ][ NicInfo::BOOTSTRAP_URL ] == nil && !explicit_url
        bootstrap = Bootstrap.new( @appctx )
        if qtype == QueryType::BY_SERVER_HELP
          qtype = guess_query_value_type( query )
        end
        case qtype
          when QueryType::BY_IP4_ADDR
            bootstrap_url = bootstrap.find_url_by_ip( query[ 0 ] )
          when QueryType::BY_IP6_ADDR
            bootstrap_url = bootstrap.find_url_by_ip( query[ 0 ] )
          when QueryType::BY_IP4_CIDR
            bootstrap_url = bootstrap.find_url_by_ip( query[ 0 ] )
          when QueryType::BY_IP6_CIDR
            bootstrap_url = bootstrap.find_url_by_ip( query[ 0 ] )
          when QueryType::BY_AS_NUMBER
            bootstrap_url = bootstrap.find_url_by_as(query[0 ] )
          when QueryType::BY_DOMAIN
            bootstrap_url = bootstrap.find_url_by_domain( query[ 0 ] )
          when QueryType::BY_NAMESERVER
            bootstrap_url = bootstrap.find_url_by_domain( query[0 ] )
          when QueryType::BY_ENTITY_HANDLE
            bootstrap_url = bootstrap.find_url_by_entity( query[0 ] )
          when QueryType::SRCH_ENTITY_BY_NAME
            bootstrap_url = @appctx.config[ NicInfo::BOOTSTRAP ][ NicInfo::ENTITY_ROOT_URL ]
          when QueryType::SRCH_DOMAIN_BY_NAME
            bootstrap_url = bootstrap.find_url_by_domain( query[ 0 ] )
          when QueryType::SRCH_DOMAIN_BY_NSNAME
            bootstrap_url = bootstrap.find_url_by_domain( query[ 0 ] )
          when QueryType::SRCH_DOMAIN_BY_NSIP
            bootstrap_url = @appctx.config[ NicInfo::BOOTSTRAP ][ NicInfo::DOMAIN_ROOT_URL ]
          when QueryType::SRCH_NS_BY_NAME
            bootstrap_url = bootstrap.find_url_by_domain( query[0 ] )
          when QueryType::SRCH_NS_BY_IP
            bootstrap_url = bootstrap.find_url_by_ip( query[ 0 ] )
          else
            bootstrap_url = @appctx.config[ NicInfo::BOOTSTRAP ][ NicInfo::HELP_ROOT_URL ]
        end
      end
      begin
        rdap_url = nil
        unless explicit_url
          path = create_resource_url( query, qtype )
          rdap_url = make_rdap_url( bootstrap_url, path)
        else
          rdap_url = query[0]
        end
        retval.data = get( rdap_url, 0, true, bootstrap_url )
        retval.json_data = JSON.load retval.data
        if (ec = retval.json_data[ NicInfo::NICINFO_DEMO_ERROR ]) != nil
          res = MyHTTPResponse.new( "1.1", ec, "Demo Exception" )
          res["content-type"] = NicInfo::RDAP_CONTENT_TYPE
          res.body=retval.data
          raise Net::HTTPServerException.new( "Demo Exception", res )
        end
        inspect_rdap_compliance retval.json_data
        cache_self_references retval.json_data
        retval.code = 200
        retval.error_state = false
      rescue JSON::ParserError => a
        @appctx.logger.mesg( "Server returned invalid JSON!", NicInfo::AttentionType::ERROR )
        retval.error_state = true
        retval.exception = a
      rescue SocketError => a
        @appctx.logger.mesg(a.message, NicInfo::AttentionType::ERROR )
        retval.error_state = true
        retval.exception = a
      rescue ArgumentError => a
        @appctx.logger.mesg(a.message, NicInfo::AttentionType::ERROR )
        retval.error_state = true
        retval.exception = a
      rescue Net::HTTPServerException => e
        case e.response.code
          when "200"
            @appctx.logger.mesg( e.message, NicInfo::AttentionType::SUCCESS )
            retval.code = 200
          when "401"
            @appctx.logger.mesg("Authorization is required.", NicInfo::AttentionType::ERROR )
            handle_error_response(e,retval)
          when "404"
            @appctx.logger.mesg("Query yielded no results.", NicInfo::AttentionType::INFO )
            handle_error_response( e, retval )
          else
            @appctx.logger.mesg("Error #{e.response.code}.", NicInfo::AttentionType::ERROR )
            handle_error_response( e, retval )
        end
        @appctx.logger.trace("Server response code was " + e.response.code)
      rescue Net::HTTPFatalError => e
        case e.response.code
          when "500"
            @appctx.logger.mesg("RDAP server is reporting an internal error.", NicInfo::AttentionType::ERROR )
            handle_error_response( e, retval )
          when "501"
            @appctx.logger.mesg("RDAP server does not implement the query.", NicInfo::AttentionType::ERROR )
            handle_error_response( e, retval )
          when "503"
            @appctx.logger.mesg("RDAP server is reporting that it is unavailable.", NicInfo::AttentionType::ERROR )
            handle_error_response( e, retval )
          else
            @appctx.logger.mesg("Error #{e.response.code}.", NicInfo::AttentionType::ERROR )
            handle_error_response( e, retval)
        end
        @appctx.logger.trace("Server response code was " + e.response.code)
      rescue Net::HTTPRetriableError => e
        retval.error_state = true
        retval.exception = e
        @appctx.logger.mesg("Too many redirections, retries, or a redirect loop has been detected." )
      end

      return retval
    end

    # Creates a query from a query type
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
          tree = @appctx.load_as_yaml(NicInfo::ARININFO_LASTTREE_YAML)
          path = tree.find_rest_ref(args[0])
          raise ArgumentError.new("Unable to find result for " + args[0]) unless path
        when QueryType::BY_ENTITY_HANDLE
          path << "entity/" << URI.escape( args[ 0 ] )
        when QueryType::SRCH_ENTITY_BY_NAME
          case args.length
            when 1
              path << "entities?fn=" << URI.escape( args[ 0 ] )
            when 2
              path << "entities?fn=" << URI.escape( args[ 0 ] + " " + args[ 1 ] )
            when 3
              path << "entities?fn=" << URI.escape( args[ 0 ] + " " + args[ 1 ] + " " + args[ 2 ] )
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

    def make_rdap_url( base_url, resource_path )
      retval = base_url
      unless base_url.end_with?("/")
        retval = retval + "/"
      end
      retval = retval + resource_path
      return retval
    end

    # Do an HTTP GET with the path.
    def get url, try, expect_rdap = true, tracking_url = nil

      data = @appctx.cache.get(url)
      if data == nil

        @appctx.logger.trace("Issuing GET for " + url)
        tracking_url = url if tracking_url == nil
        tracker = @appctx.tracked_urls[ tracking_url ]
        if tracker
          tracker.queried
        else
          tracker = TrackedUrl.new( tracking_url )
          @appctx.tracked_urls[ tracking_url ] = tracker
        end
        uri = URI.parse( URI::encode( url ) )
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
          if @appctx.config[ NicInfo::SECURITY ][ NicInfo::TRY_INSECURE ]
            @appctx.logger.mesg( "Secure connection failed. Trying insecure connection." )
            uri.scheme = "http"
            return get( uri.to_s, try, expect_rdap, tracking_url )
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
                @appctx.conf_msgs << "Server responded with non-RDAP content type but it is JSON"
              end
            end
            data = res.body
            @appctx.cache.create_or_update(url, data)
          else
            if res.code == "301" or res.code == "302" or res.code == "303" or res.code == "307" or res.code == "308"
              res.error! if try >= 5
              location = res["location"]
              @appctx.cache.create_or_update( url, NicInfo::REDIRECT_TO + location )
              return get( location, try + 1, expect_rdap, tracking_url )
            end
            res.error!
        end #end case

      elsif data.start_with?( NicInfo::REDIRECT_TO )
        location = data.sub( NicInfo::REDIRECT_TO, "" ).strip
        return get( location, try + 1, expect_rdap, tracking_url)
      end #end if

      return data

    end #end def

    def handle_error_response ( exception, rdap_response )
      res = exception.response
      rdap_response.code = res.code.to_i
      rdap_response.data = res.body
      rdap_response.error_state = true
      rdap_response.exception = exception
      if res["content-type"] == NicInfo::RDAP_CONTENT_TYPE && res.body && res.body.to_s.size > 0
        rdap_response.json_data = JSON.load( res.body )
        inspect_rdap_compliance rdap_response.json_data
      end
    end


    def inspect_rdap_compliance json
      rdap_conformance = json[ "rdapConformance" ]
      if rdap_conformance
        rdap_conformance.each do |conformance|
          @appctx.logger.trace( "Server conforms to #{conformance}", NicInfo::AttentionType::SECONDARY )
        end
      else
        @appctx.conf_msgs << "Response has no RDAP Conformance level specified."
      end
    end

    def cache_self_references json_data
      links = NicInfo::get_links json_data, @appctx
      if links
        self_link = NicInfo.get_self_link links
        if self_link
          pretty = JSON::pretty_generate( json_data )
          @appctx.cache.create( self_link, pretty )
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

  end

  class RDAPQueryGuess

    attr_accessor :appctx

    def initialize( appctx )
      @appctx = appctx
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
            @appctx.logger.trace("Interpretting " + old + " as autonomous system number " + args[0])
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

  end

end
