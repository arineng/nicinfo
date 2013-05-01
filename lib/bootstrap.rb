# Copyright (C) 2013 American Registry for Internet Numbers
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
require 'constants'
require 'ipaddr'

module NicInfo

  class Bootstrap

    def initialize config
      @config = config
      @RIR_URLS =
      {
        "IANA",                     NicInfo::IP_ROOT_URL,
        "ARIN",                     NicInfo::ARIN_URL,
        "Administered by ARIN",     NicInfo::ARIN_URL,
        "Assigned by ARIN",         NicInfo::ARIN_URL,
        "APNIC",                    NicInfo::APNIC_URL,
        "Administered by APNIC",    NicInfo::APNIC_URL,
        "Assigned by APNIC",        NicInfo::APNIC_URL,
        "AFRINIC",                  NicInfo::AFRINIC_URL,
        "Administered by AFRINIC",  NicInfo::AFRINIC_URL,
        "Assigned by AFRINIC",      NicInfo::AFRINIC_URL,
        "RIPE NCC",                 NicInfo::RIPE_URL,
        "Administered by RIPE NCC", NicInfo::RIPE_URL,
        "Assigned by RIPE NCC",     NicInfo::RIPE_URL,
        "LACNIC",                   NicInfo::LACNIC_URL,
        "Administered by LACNIC",   NicInfo::LACNIC_URL,
        "Assigned by LACNIC",       NicInfo::LACNIC_URL
      }
    end

    def find_rir_by_ip addr
      retval = nil
      if ! addr.instance_of? IPAddr
        addr = IPAddr.new addr
      end
      file = File.new( File.join( File.dirname( __FILE__ ) , NicInfo::V6_ALLOCATIONS ), "r" ) if addr.ipv6?
      file = File.new( File.join( File.dirname( __FILE__ ) , NicInfo::V4_ALLOCATIONS ), "r" ) if addr.ipv4?
      doc = REXML::Document.new file
      doc.elements.each( 'registry/record' ) do |element|
        if addr.ipv6?
          prefix = IPAddr.new element.elements[ "prefix" ].text if addr.ipv6?
        else
          prefix = IPAddr.new( element.elements[ "prefix" ].text.split( "/" )[ 0 ] + ".0.0.0" )
          prefix = prefix.mask( 8 )
        end
        retval = element.elements[ "description" ].text if prefix.include?( addr ) if addr.ipv6?
        retval = element.elements[ "designation" ].text if prefix.include?( addr ) if addr.ipv4?
        break if retval
      end
      retval
    end

    def find_rir_url_by_ip addr
      rir = find_rir_by_ip addr
      retval = @config.config[ NicInfo::BOOTSTRAP ][ @RIR_URLS[ rir ] ]
      retval = @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::IP_ROOT_URL ] if retval == nil
      return retval
    end

    def find_rir_by_as as
      retval = nil
      file = File.new( File.join( File.dirname( __FILE__ ) , NicInfo::AS_ALLOCATIONS ), "r" )
      doc = REXML::Document.new file
      doc.elements.each( 'registry/registry/record' ) do |element|
        numbers = element.elements[ "number" ].text.split( "-" )
        min = numbers[ 0 ].to_i
        max = numbers[ -1 ].to_i
        if (as >= min ) && (as <= max)
          retval = element.elements[ "description" ].text
          break
        end
      end
      retval
    end

    def get_ip4_by_inaddr inaddr
      inaddr.sub!( /\.in\-addr\.arpa\.?/, "")
      a = inaddr.split( "." ).reverse
      ip = Array.new( 4 ).fill( 0 )
      for i in 0..a.length-1 do
        ip[ i ] = a[ i ].to_i
      end
      return IPAddr.new( ip.join( "." ) )
    end

    def get_ip6_by_inaddr inaddr
      inaddr.sub!( /\.ip6\.arpa\.?/, "")
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
      domain.sub!( /\.$/, '' ) #remove trailing dot if there is one
      if domain.end_with?( ".ip6.arpa" )
        addr = get_ip6_by_inaddr domain
        retval = find_rir_url_by_ip addr
      elsif domain.end_with?( ".in-addr.arpa" )
        addr = get_ip4_by_inaddr domain
        retval = find_rir_url_by_ip addr
      else
        tld = domain.split( '.' ).last
        retval = @config.config[ NicInfo::BOOTSTRAP ][ tld + "_url" ]
        retval = @config.config[ NicInfo::BOOTSTRAP ][ NicInfo::DOMAIN_ROOT_URL ] if retval == nil
      end
      return retval
    end

  end

end

