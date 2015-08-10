# Copyright (C) 2013,2014 American Registry for Internet Numbers
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

require 'rexml/document'
require 'nicinfo/constants'
require 'ipaddr'
require 'json'

module NicInfo

  class Bootstrap

    def initialize config
      @config = config
    end


    def find_url_by_ip addr
      retval = nil
      if ! addr.instance_of? IPAddr
        addr = IPAddr.new addr
      end
      file = File.join( @config.rdap_bootstrap_dir , NicInfo::IPV6_BOOTSTRAP ) if addr.ipv6?
      file = File.join( @config.rdap_bootstrap_dir , NicInfo::IPV4_BOOTSTRAP ) if addr.ipv4?
      data = JSON.parse( File.read( file ) )
      services = get_services data
      services.each do |service|
        service[ 0 ].each do |service_entry|
          if addr.ipv6?
            prefix = IPAddr.new( service_entry )
          else
            entry = service_entry.split( "/" )[0].to_i.to_s + ".0.0.0"
            prefix = IPAddr.new( entry )
            prefix = prefix.mask( 8 )
          end
          if prefix.include?( addr )
            retval = get_service_url( service[ 1 ] )
            break
          end
        end
      end if services
      retval = @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::IP_ROOT_URL ] if retval == nil
      return retval
    end

    def find_url_by_as as
      if as.instance_of? String
        as = as.sub( /^AS/i, '')
        as = as.to_i
      end
      retval = nil
      file = File.join( @config.rdap_bootstrap_dir , NicInfo::ASN_BOOTSTRAP )
      data = JSON.parse( File.read( file ) )
      services = get_services data
      services.each do |service|
        service[ 0 ].each do |service_entry|
          numbers = service_entry.split( "-" )
          min = numbers[ 0 ].to_i
          max = numbers[ -1 ].to_i
          if (as >= min ) && (as <= max)
            retval = get_service_url( service[ 1 ] )
            break
          end
        end
      end if services
      retval = @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::AS_ROOT_URL ] if retval == nil
      return retval
    end

    def get_ip4_by_inaddr inaddr
      inaddr = inaddr.sub( /\.in\-addr\.arpa\.?/, "")
      a = inaddr.split( "." ).reverse
      ip = Array.new( 4 ).fill( 0 )
      for i in 0..a.length-1 do
        ip[ i ] = a[ i ].to_i
      end
      return IPAddr.new( ip.join( "." ) )
    end

    def get_ip6_by_inaddr inaddr
      inaddr = inaddr.sub( /\.ip6\.arpa\.?/, "")
      a = inaddr.split( "." ).reverse.join
      ip = Array.new( 16 ).fill( 0 )
      i = 0
      while i <= a.length-1 do
        ip[ i/2 ] = ( a[ i..i+1 ].to_i(16) )
        i = i +2
      end
      ipstr = ""
      i = 0
      while i <= ip.length-1 do
        ipstr << ("%02X" % ip[i])
        if ((i+1) % 2) == 0
          ipstr << ":" if i != ip.length-1
        end
        i = i +1
      end
      return IPAddr.new( ipstr )
    end

    def find_url_by_domain domain
      retval = nil
      domain = domain.sub( /\.$/, '' ) #remove trailing dot if there is one
      if domain.end_with?( ".ip6.arpa" )
        addr = get_ip6_by_inaddr domain
        retval = find_url_by_ip addr
      elsif domain.end_with?( ".in-addr.arpa" )
        addr = get_ip4_by_inaddr domain
        retval = find_url_by_ip addr
      else
        retval = find_url_by_forward_domain domain
      end
      return retval
    end

    def find_url_by_forward_domain domain
      retval = nil
      file = File.join( @config.rdap_bootstrap_dir , NicInfo::DNS_BOOTSTRAP )
      data = JSON.parse( File.read( file ) )
      longest_domain = nil
      longest_urls = nil
      services = get_services data
      services.each do |service|
        service[ 0 ].each do |service_entry|
          if domain.end_with?( service_entry )
            if longest_domain == nil || longest_domain.length < service_entry.length
              longest_domain = service_entry
              longest_urls = service[ 1 ]
            end
          end
        end
      end if services
      if longest_urls != nil
        retval = get_service_url( longest_urls )
      end
      retval = @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::DOMAIN_ROOT_URL ] if retval == nil
      return retval
    end

    def find_url_by_entity entity_name
      retval = nil
      suffix = entity_name.downcase.split( '-' ).last
      if suffix
        file = File.join( @config.rdap_bootstrap_dir , NicInfo::ENTITY_BOOTSTRAP )
        data = JSON.parse( File.read( file ) )
        services = get_services data
        services.each do |service|
          service[ 0 ].each do |service_entry|
            if service_entry.downcase == suffix
              retval = get_service_url( service[ 1 ] )
              break
            end
          end
        end if services
      end
      retval = @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::ENTITY_ROOT_URL ] if retval == nil
      return retval
    end

    def get_services data
      rdap_bootstrap = data["rdap_bootstrap"]
      if rdap_bootstrap
        rdap_bootstrap["services"]
      end
    end

    def get_service_url service_url_array
      http_url = nil
      https_url = nil
      service_url_array.each do |url|
        if url.start_with?( "https" )
          https_url = url
        elsif url.start_with?( "http" )
          http_url = url
        end
      end
      if https_url != nil
        return https_url
      end
      #else
      return http_url
    end

  end

end

