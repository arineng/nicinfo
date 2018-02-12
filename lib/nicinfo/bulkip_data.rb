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

require 'ipaddr'
require 'ip'
require 'utils'

module NicInfo

  class BulkIPNetMeta

    attr_accessor :name, :region, :country, :fetch_error

    def initialize( rdap_ip, appctx )

      if rdap_ip != nil

        self_link = NicInfo.get_self_link( NicInfo.get_links( rdap_ip.object_class, appctx ) )
        @region = /.*(arin|ripe|apnic|lacnic|afrinic)\.net/.match( self_link )[1].to_upper

        registrant = nil
        rdap_ip.entities.each do |e|
          roles = e.object_class[ "roles" ]
          if roles && roles[ "registrant" ]
            registrant = e
            break;
          end
        end
        if registrant && registrant.jcard
          jcard
        end

        @fetch_error = false

      else

        @fetch_error = true

      end

    end

  end

  class BulkIPDatum

    attr_accessor :network, :total_queries, :first_query_time, :last_query_time, :meta

    def initialize( network, meta )
      @network = network
      @meta = meta
      @total_queries = 1
      @first_query_time = Time.now
      @last_query_time = Time.now
    end

    def hit
      @total_queries = @total_queries + 1
      @last_query_time = Time.now
    end

  end

  class BulkIPData

    attr_accessor :data

    def initialize
      @data = Hash.new
    end

    def hit_ipaddr( ipaddr )

      retval = false
      @data.each do |datum_net, datum|
        if datum_net.include?( ipaddr )
          datum.hit
          retval = true
          break;
        end
      end

      return retval

    end

    def hit_network( network, meta )

      unless network.is_a?( Array )
        network = [ network ]
      end

      network.each do |n|
        found = false
        @data.each do |datum_net,datum|
          if datum_net.include?( n )
            datum.hit
            found = true
            break;
          end
        end
        unless found
          d = BulkIPDatum.new( n, meta )
          @data[ n ] = d
        end
      end

    end

  end


end
